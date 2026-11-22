import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../objectbox.g.dart';
import '../../remote/active_supabase_client.dart';
import '../../remote/sync_remote_if_available.dart';
import '../db_helper.dart';
import '../model/basket_model.dart';
import '../model/customer_model.dart';
import '../model/installment_model.dart';
import '../model/sale_basket_input.dart';
import '../model/sale_basket_model.dart';
import '../model/sale_model.dart';
import '../remote_deletion.dart';
import '../sync_timestamps.dart';
import '../sync_entity_lookup.dart';
import 'customer_score_service.dart';

class SaleBasketLine {
  const SaleBasketLine({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final double price;
  final int quantity;

  double get total => price * quantity;

  String get label => quantity > 1 ? '${quantity}x $name' : name;
}

class SaleRepository {
  final DatabaseHelper _dbHelper;
  SaleRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  static double remainingBalance(Sale sale) => sale.price - sale.amountPaid;

  static bool isSaleFullyPaid(Sale sale) => remainingBalance(sale) <= 0;

  /// Valida pagamento contra o saldo restante da venda.
  static void validatePaymentAmount(Sale sale, double paymentAmount) {
    if (paymentAmount <= 0) {
      throw ArgumentError('Informe um valor de pagamento maior que zero.');
    }
    if (isSaleFullyPaid(sale)) {
      throw StateError('Venda já está quitada.');
    }
    final remaining = remainingBalance(sale);
    if (paymentAmount > remaining) {
      throw ArgumentError(
        'O pagamento não pode exceder o saldo restante da venda.',
      );
    }
  }

  Sale _withCurrentUser(Sale sale) {
    final userId = sale.userId;
    if (userId != null && userId.isNotEmpty) return sale;
    final current = currentUserId();
    if (current == null || current.isEmpty) return sale;
    return sale.copyWith(userId: current);
  }

  Future<int> registerSale(Sale value, List<SaleBasketInput> lines) async {
    SaleBasketInput.ensureValid(lines);
    final db = await _dbHelper.store;
    final customer = db.box<Customer>().get(value.customerId);
    if (customer == null || customer.isDeleted) {
      throw StateError('Cliente não encontrado.');
    }
    if (customer.isBlocked) {
      throw StateError('Cliente bloqueado não pode realizar compras.');
    }
    final identified = value.customerUuid.isEmpty
        ? value.copyWith(customerUuid: customer.uuid)
        : value;
    final sale = _withCurrentUser(identified);
    final resolvedLines = <({Basket basket, SaleBasketInput line, bool isNew})>[];
    for (final line in lines) {
      if (line.isCatalog) {
        final catalog = findBasketByUuid(db, line.basketUuid);
        if (catalog == null || catalog.isDeleted) {
          throw StateError('Cesta do catálogo não encontrada.');
        }
        resolvedLines.add((basket: catalog, line: line, isNew: false));
      } else {
        final basketCreatedAt = sale.createdAt;
        resolvedLines.add((
          basket: Basket(
            uuid: const Uuid().v4(),
            name: line.name!.trim(),
            price: line.unitPrice!,
            createdAt: basketCreatedAt,
            updatedAt: SyncTimestamps.forCreate(basketCreatedAt),
          ),
          line: line,
          isNew: true,
        ));
      }
    }

    final saleStamp = SyncTimestamps.forCreate(sale.createdAt, sale.updatedAt);
    final pendingSale = sale.copyWith(updatedAt: saleStamp, isSynced: false);
    final createdBasketIds = <int>[];
    final linkIds = <int>[];
    final saleId = db.runInTransaction(TxMode.write, () {
      final currentCustomer = db.box<Customer>().get(pendingSale.customerId);
      if (currentCustomer == null || currentCustomer.isDeleted) {
        throw StateError('Cliente não encontrado.');
      }
      if (currentCustomer.isBlocked) {
        throw StateError('Cliente bloqueado não pode realizar compras.');
      }
      final saleId = db.box<Sale>().put(pendingSale);
      for (final resolved in resolvedLines) {
        final basketId = resolved.isNew
            ? db.box<Basket>().put(resolved.basket.copyWith(isSynced: false))
            : resolved.basket.id;
        if (basketId == null) {
          throw StateError('Cesta do catálogo sem ID local.');
        }
        if (resolved.isNew) createdBasketIds.add(basketId);
        linkIds.add(
          db.box<SaleBasket>().put(
            SaleBasket(
              saleId: saleId,
              basketId: basketId,
              saleUuid: pendingSale.uuid,
              basketUuid: resolved.basket.uuid,
              quantity: resolved.line.quantity,
              createdAt: pendingSale.createdAt,
              updatedAt: saleStamp,
              isSynced: false,
            ),
          ),
        );
      }
      return saleId;
    });
    final synced = await syncRemoteIfAvailable((client) async {
      await client.from('sales').insert(pendingSale.toRemote());
      for (final resolved in resolvedLines) {
        if (!resolved.isNew) continue;
        await client.from('baskets').insert(resolved.basket.toRemote());
      }
      for (var index = 0; index < resolvedLines.length; index++) {
        final resolved = resolvedLines[index];
        await client.from('sale_baskets').insert(
          SaleBasket(
            saleId: saleId,
            basketId: 0,
            saleUuid: pendingSale.uuid,
            basketUuid: resolved.basket.uuid,
            quantity: resolved.line.quantity,
            createdAt: pendingSale.createdAt,
            updatedAt: saleStamp,
          ).toRemote(),
        );
      }
    }, debugLabel: 'sales.register');
    if (synced) {
      db.box<Sale>().put(
        pendingSale.copyWith(id: saleId, isSynced: true),
        mode: PutMode.update,
      );
      for (final basketId in createdBasketIds) {
        final basket = db.box<Basket>().get(basketId);
        if (basket == null) continue;
        db.box<Basket>().put(
          basket.copyWith(isSynced: true),
          mode: PutMode.update,
        );
      }
      for (var index = 0; index < linkIds.length; index++) {
        final link = db.box<SaleBasket>().get(linkIds[index]);
        if (link == null) continue;
        db.box<SaleBasket>().put(
          link.copyWith(isSynced: true),
          mode: PutMode.update,
        );
      }
    }
    return saleId;
  }

  Future<Sale?> getSaleById(int id) async {
    final sale = (await _dbHelper.store).box<Sale>().get(id);
    if (sale == null || sale.isDeleted) return null;
    return sale;
  }

  Future<List<Sale>> getAllSales() async {
    final query = (await _dbHelper.store)
        .box<Sale>()
        .query(Sale_.isDeleted.equals(false))
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<int> updateSale(Sale value) async {
    if (value.id == null || value.id == 0) {
      throw ArgumentError('ID obrigatório para atualizar.');
    }
    if (value.amountPaid > value.price) {
      throw ArgumentError(
        'O valor pago não pode exceder o preço total da venda.',
      );
    }
    final db = await _dbHelper.store;
    final pending = _withCurrentUser(value).copyWith(
      updatedAt: SyncTimestamps.forUpdate(),
      isSynced: false,
    );
    final updated = db.runInTransaction(TxMode.write, () {
      if (db.box<Sale>().get(pending.id!) == null) return 0;
      if (db.box<Customer>().get(pending.customerId) == null) {
        throw StateError('Cliente não encontrado.');
      }
      db.box<Sale>().put(pending, mode: PutMode.update);
      return 1;
    });
    if (updated == 0) return 0;
    final synced = await syncRemoteIfAvailable(
      (client) => client
          .from('sales')
          .update(pending.toRemote())
          .eq('id', pending.uuid),
      debugLabel: 'sales.update',
    );
    if (synced) {
      db.box<Sale>().put(
        pending.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    return 1;
  }

  Future<List<Sale>> getSalesByCustomerId(int customerId) async {
    final db = await _dbHelper.store;
    final query = db
        .box<Sale>()
        .query(
          Sale_.customerId
              .equals(customerId)
              .and(Sale_.isDeleted.equals(false)),
        )
        .order(Sale_.createdAt, flags: Order.descending)
        .order(Sale_.id, flags: Order.descending)
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @Deprecated('Use getSalesByCustomerId instead.')
  Future<List<Sale>> getSalesBycustumerId(int id) => getSalesByCustomerId(id);

  Future<List<Sale>> getLatestSales({int limit = 5}) async {
    if (limit <= 0) return [];
    final db = await _dbHelper.store;
    final query = db
        .box<Sale>()
        .query(Sale_.isDeleted.equals(false))
        .order(Sale_.createdAt, flags: Order.descending)
        .build();
    try {
      query.limit = limit;
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<List<SaleBasketLine>> getBasketLines(int saleId) async {
    final lines = await basketLinesFor([saleId]);
    return lines[saleId] ?? const [];
  }

  Future<Map<int, List<SaleBasketLine>>> basketLinesFor(
    List<int> saleIds,
  ) async {
    if (saleIds.isEmpty) return {};
    final db = await _dbHelper.store;
    final linkQuery = db
        .box<SaleBasket>()
        .query(
          SaleBasket_.saleId
              .oneOf(saleIds)
              .and(SaleBasket_.isDeleted.equals(false)),
        )
        .build();
    try {
      final links = linkQuery.find();
      final basketIds = links.map((link) => link.basketId).toSet().toList();
      final baskets = <int, Basket>{};
      if (basketIds.isNotEmpty) {
        final basketQuery = db
            .box<Basket>()
            .query(
              Basket_.id.oneOf(basketIds).and(Basket_.isDeleted.equals(false)),
            )
            .build();
        try {
          for (final basket in basketQuery.find()) {
            if (basket.id != null) baskets[basket.id!] = basket;
          }
        } finally {
          basketQuery.close();
        }
      }
      final lines = <int, List<SaleBasketLine>>{};
      for (final link in links) {
        final basket = baskets[link.basketId];
        lines.putIfAbsent(link.saleId, () => []).add(
          SaleBasketLine(
            name: basket?.name ?? '',
            price: basket?.price ?? 0,
            quantity: link.quantity,
          ),
        );
      }
      return lines;
    } finally {
      linkQuery.close();
    }
  }

  Future<Map<int, String>> basketLabelsFor(List<int> saleIds) async {
    final lines = await basketLinesFor(saleIds);
    return {
      for (final entry in lines.entries)
        entry.key: entry.value.map((line) => line.label).join(', '),
    };
  }

  Future<double> getTotalSalesAmountSince(DateTime date) async {
    final sales = await getAllSales();
    return sales
        .where((sale) => !sale.createdAt.isBefore(date))
        .fold<double>(0, (total, sale) => total + sale.price);
  }

  Future<int> getPendingCustomersCount() async {
    final db = await _dbHelper.store;
    final paidSales = db
        .box<Installment>()
        .getAll()
        .where((installment) => !installment.isDeleted && installment.isPaid)
        .map((installment) => installment.saleId)
        .toSet();
    return db
        .box<Sale>()
        .getAll()
        .where((sale) => !sale.isDeleted && !paidSales.contains(sale.id))
        .map((sale) => sale.customerId)
        .toSet()
        .length;
  }

  Future<int> deleteSale(int id) async {
    final db = await _dbHelper.store;
    final sale = db.box<Sale>().get(id);
    if (sale == null || sale.isDeleted) return 0;

    final links = _activeLinks(db, [id]);
    final baskets = _basketsOnlyUsedBy(db, links, {id});
    final installments = _activeInstallments(db, [id]);
    final now = DateTime.now();
    final marked = db.runInTransaction(TxMode.write, () {
      final current = db.box<Sale>().get(id);
      if (current == null || current.isDeleted) return 0;
      db.box<Sale>().put(
        current.copyWith(isDeleted: true, isSynced: false, updatedAt: now),
        mode: PutMode.update,
      );
      for (final link in links) {
        db.box<SaleBasket>().put(
          link.copyWith(isDeleted: true, isSynced: false, updatedAt: now),
          mode: PutMode.update,
        );
      }
      for (final basket in baskets) {
        db.box<Basket>().put(
          basket.copyWith(isDeleted: true, isSynced: false, updatedAt: now),
          mode: PutMode.update,
        );
      }
      for (final installment in installments) {
        db.box<Installment>().put(
          installment.copyWith(isDeleted: true, isSynced: false, updatedAt: now),
          mode: PutMode.update,
        );
      }
      return 1;
    });
    if (marked == 0) return 0;
    await _syncSaleDeletion(
      saleId: id,
      sale: sale,
      links: links,
      baskets: baskets,
      installments: installments,
    );
    await CustomerScoreService(dbHelper: _dbHelper).recalculate(sale.customerId);
    return 1;
  }

  Future<void> _syncSaleDeletion({
    required int saleId,
    required Sale sale,
    required List<SaleBasket> links,
    required List<Basket> baskets,
    required List<Installment> installments,
  }) async {
    final db = await _dbHelper.store;
    if (sale.uuid.isNotEmpty) {
      final synced = await _markRemoteDeleted('sales', sale.uuid);
      if (synced) {
        final current = db.box<Sale>().get(saleId);
        if (current != null) {
          db.box<Sale>().put(
            current.copyWith(isSynced: true),
            mode: PutMode.update,
          );
        }
      }
    }
    for (final link in links) {
      final synced = await _markRemoteSaleBasketDeleted(
        link.saleUuid,
        link.basketUuid,
      );
      if (!synced || link.id == null) continue;
      final current = db.box<SaleBasket>().get(link.id!);
      if (current == null) continue;
      db.box<SaleBasket>().put(
        current.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    for (final basket in baskets) {
      if (basket.uuid.isEmpty) continue;
      final synced = await _markRemoteDeleted('baskets', basket.uuid);
      if (!synced || basket.id == null) continue;
      final current = db.box<Basket>().get(basket.id!);
      if (current == null) continue;
      db.box<Basket>().put(
        current.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    for (final installment in installments) {
      if (installment.uuid.isEmpty) continue;
      final synced = await _markRemoteDeleted('installments', installment.uuid);
      if (!synced || installment.id == null) continue;
      final current = db.box<Installment>().get(installment.id!);
      if (current == null) continue;
      db.box<Installment>().put(
        current.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
  }

  List<SaleBasket> _activeLinks(Store db, List<int> saleIds) {
    if (saleIds.isEmpty) return [];
    final query = db
        .box<SaleBasket>()
        .query(
          SaleBasket_.saleId
              .oneOf(saleIds)
              .and(SaleBasket_.isDeleted.equals(false)),
        )
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  List<Installment> _activeInstallments(Store db, List<int> saleIds) {
    if (saleIds.isEmpty) return [];
    final query = db
        .box<Installment>()
        .query(
          Installment_.saleId
              .oneOf(saleIds)
              .and(Installment_.isDeleted.equals(false)),
        )
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  List<Basket> _basketsOnlyUsedBy(
    Store db,
    List<SaleBasket> links,
    Set<int> saleIds,
  ) {
    final baskets = <Basket>[];
    final seen = <int>{};
    for (final link in links) {
      if (!seen.add(link.basketId)) continue;
      final basket = db.box<Basket>().get(link.basketId);
      if (basket == null || basket.isDeleted) continue;
      final others = db
          .box<SaleBasket>()
          .query(SaleBasket_.basketId.equals(link.basketId))
          .build();
      try {
        final usedElsewhere = others.find().any(
          (other) => !other.isDeleted && !saleIds.contains(other.saleId),
        );
        if (!usedElsewhere) baskets.add(basket);
      } finally {
        others.close();
      }
    }
    return baskets;
  }

  Future<bool> _markRemoteDeleted(String table, String id) async {
    if (id.isEmpty) return false;
    return syncRemoteIfAvailable(
      (client) => client
          .from(table)
          .update(remoteDeletionStamp(DateTime.now()))
          .eq('id', id),
      debugLabel: '$table.delete',
    );
  }

  Future<bool> _markRemoteSaleBasketDeleted(
    String saleUuid,
    String basketUuid,
  ) async {
    if (saleUuid.isEmpty || basketUuid.isEmpty) return false;
    return syncRemoteIfAvailable(
      (client) => client
          .from('sale_baskets')
          .update(remoteDeletionStamp(DateTime.now()))
          .eq('sale_id', saleUuid)
          .eq('basket_id', basketUuid),
      debugLabel: 'sale_baskets.delete',
    );
  }

  Future<void> pushUnsynced() async {
    final db = await _dbHelper.store;
    await _pushUnsyncedSales(db);
  }

  Future<void> _pushUnsyncedSales(Store db) async {
    final query = db.box<Sale>().query(Sale_.isSynced.equals(false)).build();
    List<Sale> pending;
    try {
      pending = query.find();
    } finally {
      query.close();
    }
    for (final sale in pending) {
      var synced = false;
      if (sale.uuid.isNotEmpty) {
        try {
          if (sale.isDeleted) {
            synced = await _markRemoteDeleted('sales', sale.uuid);
          } else {
            final ready = _withCurrentUser(sale);
            await Supabase.instance.client.from('sales').upsert(ready.toRemote());
            db.box<Sale>().put(ready.copyWith(isSynced: true), mode: PutMode.update);
            continue;
          }
        } catch (_) {
          synced = false;
        }
      }
      if (!synced) continue;
      db.box<Sale>().put(sale.copyWith(isSynced: true), mode: PutMode.update);
    }
  }

  Future<void> pullSince(DateTime since) async {
    debugPrint('[SaleRepository.pullSince] since=${since.toUtc().toIso8601String()}');
    final db = await _dbHelper.store;
    await _pullSalesSince(db, since);
  }

  Future<void> _pullSalesSince(Store db, DateTime since) async {
    final iso = since.toUtc().toIso8601String();
    final List<dynamic> rows;
    try {
      rows = await Supabase.instance.client
          .from('sales')
          .select()
          .gt('updated_at', iso);
    } catch (e, stackTrace) {
      debugPrint('[SaleRepository.pullSince] erro ao buscar: $e');
      debugPrint('$stackTrace');
      return;
    }
    debugPrint('[SaleRepository.pullSince] ${rows.length} registro(s) remoto(s)');
    var merged = 0;
    var skipped = 0;
    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final remote = Sale.fromMap(raw);
      if (remote.customerUuid.isEmpty) {
        skipped++;
        continue;
      }
      final customer = findCustomerByUuid(db, remote.customerUuid);
      if (customer?.id == null) {
        skipped++;
        continue;
      }
      final existing = findSaleByUuid(db, remote.uuid);
      final mergedSale = remote.copyWith(
        id: existing?.id,
        customerId: customer!.id!,
        isSynced: true,
      );
      db.box<Sale>().put(
        mergedSale,
        mode: existing == null ? PutMode.put : PutMode.update,
      );
      merged++;
    }
    debugPrint(
      '[SaleRepository.pullSince] $merged venda(s) mesclada(s), '
      '$skipped ignorada(s)',
    );
  }

}

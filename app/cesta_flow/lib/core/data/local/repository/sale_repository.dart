import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/basket_model.dart';
import '../model/customer_model.dart';
import '../model/installment_model.dart';
import '../model/sale_basket_input.dart';
import '../model/sale_basket_model.dart';
import '../model/sale_model.dart';
import '../sync_entity_lookup.dart';

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

  Future<int> registerSale(Sale value, List<SaleBasketInput> lines) async {
    SaleBasketInput.ensureValid(lines);
    final db = await _dbHelper.store;
    final customer = db.box<Customer>().get(value.customerId);
    if (customer == null || customer.isDeleted) {
      throw StateError('Cliente não encontrado.');
    }
    final sale = value.customerUuid.isEmpty
        ? value.copyWith(customerUuid: customer.uuid)
        : value;
    final resolvedLines = <({Basket basket, SaleBasketInput line, bool isNew})>[];
    for (final line in lines) {
      if (line.isCatalog) {
        final catalog = findBasketByUuid(db, line.basketUuid);
        if (catalog == null || catalog.isDeleted) {
          throw StateError('Cesta do catálogo não encontrada.');
        }
        resolvedLines.add((basket: catalog, line: line, isNew: false));
      } else {
        resolvedLines.add((
          basket: Basket(
            uuid: const Uuid().v4(),
            name: line.name!.trim(),
            price: line.unitPrice!,
            createdAt: sale.createdAt,
          ),
          line: line,
          isNew: true,
        ));
      }
    }

    var synced = true;
    try {
      await Supabase.instance.client.from('sales').insert(sale.toRemote());
      for (final resolved in resolvedLines) {
        if (resolved.isNew) {
          await Supabase.instance.client
              .from('baskets')
              .insert(resolved.basket.toRemote());
        }
        await Supabase.instance.client.from('sale_baskets').insert(
          SaleBasket(
            saleId: 0,
            basketId: 0,
            saleUuid: sale.uuid,
            basketUuid: resolved.basket.uuid,
            quantity: resolved.line.quantity,
            createdAt: sale.createdAt,
          ).toRemote(),
        );
      }
    } catch (_) {
      synced = false;
    }
    final saleAfterSync = sale.copyWith(isSynced: synced);
    return db.runInTransaction(TxMode.write, () {
      final currentCustomer = db.box<Customer>().get(saleAfterSync.customerId);
      if (currentCustomer == null || currentCustomer.isDeleted) {
        throw StateError('Cliente não encontrado.');
      }
      final saleId = db.box<Sale>().put(saleAfterSync);
      for (final resolved in resolvedLines) {
        final basketAfterSync = resolved.isNew
            ? resolved.basket.copyWith(isSynced: synced)
            : resolved.basket;
        final basketId = resolved.isNew
            ? db.box<Basket>().put(basketAfterSync)
            : basketAfterSync.id!;
        if (!resolved.isNew && basketAfterSync.id == null) {
          throw StateError('Cesta do catálogo sem ID local.');
        }
        db.box<SaleBasket>().put(
          SaleBasket(
            saleId: saleId,
            basketId: basketId,
            saleUuid: saleAfterSync.uuid,
            basketUuid: basketAfterSync.uuid,
            quantity: resolved.line.quantity,
            createdAt: saleAfterSync.createdAt,
            isSynced: synced,
          ),
        );
      }
      return saleId;
    });
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
    bool isSynced = true;
    try {
      await Supabase.instance.client
          .from('sales')
          .update(value.toRemote())
          .eq('id', value.uuid);
    } catch (_) {
      isSynced = false;
    }
    final valueAfterSync = value.copyWith(isSynced: isSynced);
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Sale>().get(valueAfterSync.id!) == null) return 0;
      if (db.box<Customer>().get(valueAfterSync.customerId) == null) {
        throw StateError('Cliente não encontrado.');
      }
      db.box<Sale>().put(valueAfterSync, mode: PutMode.update);
      return 1;
    });
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
    final saleSynced = await _markRemoteDeleted('sales', sale.uuid);
    final linkSynced = <bool>[
      for (final link in links)
        await _markRemoteSaleBasketDeleted(link.saleUuid, link.basketUuid),
    ];
    final basketSynced = <bool>[
      for (final basket in baskets)
        await _markRemoteDeleted('baskets', basket.uuid),
    ];
    final installmentSynced = <bool>[
      for (final installment in installments)
        await _markRemoteDeleted('installments', installment.uuid),
    ];

    return db.runInTransaction(TxMode.write, () {
      final current = db.box<Sale>().get(id);
      if (current == null || current.isDeleted) return 0;
      db.box<Sale>().put(
        current.copyWith(
          isDeleted: true,
          isSynced: saleSynced,
          updatedAt: now,
        ),
        mode: PutMode.update,
      );
      for (var index = 0; index < links.length; index++) {
        db.box<SaleBasket>().put(
          links[index].copyWith(
            isDeleted: true,
            isSynced: linkSynced[index],
            updatedAt: now,
          ),
          mode: PutMode.update,
        );
      }
      for (var index = 0; index < baskets.length; index++) {
        db.box<Basket>().put(
          baskets[index].copyWith(
            isDeleted: true,
            isSynced: basketSynced[index],
            updatedAt: now,
          ),
          mode: PutMode.update,
        );
      }
      for (var index = 0; index < installments.length; index++) {
        db.box<Installment>().put(
          installments[index].copyWith(
            isDeleted: true,
            isSynced: installmentSynced[index],
            updatedAt: now,
          ),
          mode: PutMode.update,
        );
      }
      return 1;
    });
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
    try {
      await Supabase.instance.client
          .from(table)
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _markRemoteSaleBasketDeleted(
    String saleUuid,
    String basketUuid,
  ) async {
    if (saleUuid.isEmpty || basketUuid.isEmpty) return false;
    try {
      await Supabase.instance.client
          .from('sale_baskets')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('sale_id', saleUuid)
          .eq('basket_id', basketUuid);
      return true;
    } catch (_) {
      return false;
    }
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
            await Supabase.instance.client.from('sales').upsert(sale.toRemote());
            synced = true;
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
    } catch (_) {
      return;
    }
    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final remote = Sale.fromMap(raw);
      if (remote.customerUuid.isEmpty) continue;
      final customer = findCustomerByUuid(db, remote.customerUuid);
      if (customer?.id == null) continue;
      final existing = findSaleByUuid(db, remote.uuid);
      final merged = remote.copyWith(
        id: existing?.id,
        customerId: customer!.id!,
        isSynced: true,
      );
      db.box<Sale>().put(
        merged,
        mode: existing == null ? PutMode.put : PutMode.update,
      );
    }
  }

}

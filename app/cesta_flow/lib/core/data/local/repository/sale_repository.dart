import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/basket_model.dart';
import '../model/customer_model.dart';
import '../model/installment_model.dart';
import '../model/sale_basket_model.dart';
import '../model/sale_model.dart';

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

  Future<int> registerSale(
    Sale value, {
    String basketName = '',
    double? basketPrice,
    int quantity = 1,
  }) async {
    final db = await _dbHelper.store;
    final customer = db.box<Customer>().get(value.customerId);
    if (customer == null) {
      throw StateError('Cliente não encontrado.');
    }
    final sale = value.customerUuid.isEmpty
        ? value.copyWith(customerUuid: customer.uuid)
        : value;
    final basket = Basket(
      uuid: const Uuid().v4(),
      name: basketName,
      price: basketPrice ?? sale.price,
      createdAt: sale.createdAt,
    );
    var synced = true;
    try {
      await Supabase.instance.client.from('sales').insert(sale.toRemote());
      await Supabase.instance.client.from('baskets').insert(basket.toRemote());
      await Supabase.instance.client.from('sale_baskets').insert(
        SaleBasket(
          saleId: 0,
          basketId: 0,
          saleUuid: sale.uuid,
          basketUuid: basket.uuid,
          quantity: quantity,
          createdAt: sale.createdAt,
        ).toRemote(),
      );
    } catch (_) {
      synced = false;
    }
    final saleAfterSync = sale.copyWith(isSynced: synced);
    final basketAfterSync = basket.copyWith(isSynced: synced);
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Customer>().get(saleAfterSync.customerId) == null) {
        throw StateError('Cliente não encontrado.');
      }
      final basketId = db.box<Basket>().put(basketAfterSync);
      final saleId = db.box<Sale>().put(saleAfterSync);
      db.box<SaleBasket>().put(
        SaleBasket(
          saleId: saleId,
          basketId: basketId,
          saleUuid: saleAfterSync.uuid,
          basketUuid: basketAfterSync.uuid,
          quantity: quantity,
          createdAt: saleAfterSync.createdAt,
          isSynced: synced,
        ),
      );
      return saleId;
    });
  }

  Future<Sale?> getSaleById(int id) async =>
      (await _dbHelper.store).box<Sale>().get(id);
  Future<List<Sale>> getAllSales() async =>
      (await _dbHelper.store).box<Sale>().getAll();

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
        .query(Sale_.customerId.equals(customerId))
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
        .query()
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
        .query(SaleBasket_.saleId.oneOf(saleIds))
        .build();
    try {
      final links = linkQuery.find();
      final basketIds = links.map((link) => link.basketId).toSet().toList();
      final baskets = <int, Basket>{};
      if (basketIds.isNotEmpty) {
        final basketQuery = db
            .box<Basket>()
            .query(Basket_.id.oneOf(basketIds))
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
        .where((installment) => installment.isPaid)
        .map((installment) => installment.saleId)
        .toSet();
    return db
        .box<Sale>()
        .getAll()
        .where((sale) => !paidSales.contains(sale.id))
        .map((sale) => sale.customerId)
        .toSet()
        .length;
  }

  Future<int> deleteSale(int id) async {
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      _removeSaleChildren(db, id);
      return db.box<Sale>().remove(id) ? 1 : 0;
    });
  }

  void _removeSaleChildren(Store db, int saleId) {
    final installments = db
        .box<Installment>()
        .query(Installment_.saleId.equals(saleId))
        .build();
    try {
      installments.remove();
    } finally {
      installments.close();
    }
    final links = db
        .box<SaleBasket>()
        .query(SaleBasket_.saleId.equals(saleId))
        .build();
    try {
      links.remove();
    } finally {
      links.close();
    }
  }
}

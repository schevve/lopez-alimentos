import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/customer_model.dart';
import '../model/sale_model.dart';
import '../model/payment_model.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper;
  SaleRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerSale(Sale value) async {
    final db = await _dbHelper.store;
    if (db.box<Customer>().get(value.customerId) == null) {
      throw StateError('Cliente não encontrado.');
    }
    bool isSynced = true;
    try {
      await Supabase.instance.client.from('sales').insert(value.toMap());
    } catch (_) {
      isSynced = false;
    }
    final valueAfterSync = value.copyWith(isSynced: isSynced);
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Customer>().get(valueAfterSync.customerId) == null) {
        throw StateError('Cliente não encontrado.');
      }
      return db.box<Sale>().put(valueAfterSync);
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
          .update(value.toMap())
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
        .order(Sale_.date, flags: Order.descending)
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
        .order(Sale_.date, flags: Order.descending)
        .build();
    try {
      query.limit = limit;
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<double> getTotalSalesAmountSince(DateTime date) async {
    final sales = await getAllSales();
    return sales
        .where((s) => !s.date.isBefore(date))
        .fold<double>(0, (total, sale) => total + sale.price * sale.quantity);
  }

  Future<int> getPendingCustomersCount() async {
    final db = await _dbHelper.store;
    final paidSales = db.box<Payment>().getAll().map((p) => p.saleId).toSet();
    return db
        .box<Sale>()
        .getAll()
        .where((s) => !paidSales.contains(s.id))
        .map((s) => s.customerId)
        .toSet()
        .length;
  }

  Future<int> deleteSale(int id) async {
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      final query = db.box<Payment>().query(Payment_.saleId.equals(id)).build();
      try {
        query.remove();
      } finally {
        query.close();
      }
      return db.box<Sale>().remove(id) ? 1 : 0;
    });
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/customer_model.dart';
import '../model/sale_model.dart';
import 'sale_repository.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper;
  CustomerRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerCustomer(Customer value) async {
    bool isSynced = true;
    try {
      await Supabase.instance.client.from('customers').insert(value.toRemote());
    } catch (_) {
      isSynced = false;
    }
    final db = await _dbHelper.store;
    final valueAfterSync = value.copyWith(isSynced: isSynced);
    return db.runInTransaction(TxMode.write, () {
      return db.box<Customer>().put(valueAfterSync);
    });
  }

  Future<Customer?> getCustomerById(int id) async {
    final customer = (await _dbHelper.store).box<Customer>().get(id);
    if (customer == null || customer.isDeleted) return null;
    return customer;
  }

  Future<List<Customer>> getAllCustomers() async {
    final query = (await _dbHelper.store)
        .box<Customer>()
        .query(Customer_.isDeleted.equals(false))
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
  Future<int> updateCustomer(Customer value) async {
    if (value.id == null || value.id == 0) {
      throw ArgumentError('ID obrigatório para atualizar.');
    }
    bool isSynced = true;
    try {
      await Supabase.instance.client
          .from('customers')
          .update(value.toRemote())
          .eq('id', value.uuid);
    } catch (_) {
      isSynced = false;
    }
    final valueAfterSync = value.copyWith(isSynced: isSynced);
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Customer>().get(valueAfterSync.id!) == null) return 0;

      db.box<Customer>().put(valueAfterSync, mode: PutMode.update);
      return 1;
    });
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.store;
    final customer = db.box<Customer>().get(id);
    if (customer == null || customer.isDeleted) return 0;

    final sales = db
        .box<Sale>()
        .query(
          Sale_.customerId.equals(id).and(Sale_.isDeleted.equals(false)),
        )
        .build();
    final saleIds = sales.find().map((sale) => sale.id!).toList();
    sales.close();

    final salesRepository = SaleRepository(dbHelper: _dbHelper);
    for (final saleId in saleIds) {
      await salesRepository.deleteSale(saleId);
    }

    var synced = false;
    if (customer.uuid.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('customers')
            .update({
              'is_deleted': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', customer.uuid);
        synced = true;
      } catch (_) {
        synced = false;
      }
    }

    return db.runInTransaction(TxMode.write, () {
      final current = db.box<Customer>().get(id);
      if (current == null || current.isDeleted) return 0;
      db.box<Customer>().put(
        current.copyWith(
          isDeleted: true,
          isSynced: synced,
          updatedAt: DateTime.now(),
        ),
        mode: PutMode.update,
      );
      return 1;
    });
  }
}

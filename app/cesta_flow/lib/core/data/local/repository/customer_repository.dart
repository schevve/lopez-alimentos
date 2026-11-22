import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectbox.g.dart';
import '../../remote/sync_remote_if_available.dart';
import '../db_helper.dart';
import '../model/customer_model.dart';
import '../model/sale_model.dart';
import '../remote_deletion.dart';
import '../sync_timestamps.dart';
import '../sync_entity_lookup.dart';
import 'sale_repository.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper;
  CustomerRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerCustomer(Customer value) async {
    final db = await _dbHelper.store;
    final pending = value.copyWith(
      updatedAt: SyncTimestamps.forCreate(value.createdAt, value.updatedAt),
      isSynced: false,
    );
    final id = db.runInTransaction(TxMode.write, () {
      return db.box<Customer>().put(pending);
    });
    final saved = pending.copyWith(id: id);
    final synced = await syncRemoteIfAvailable(
      (client) => client.from('customers').insert(saved.toRemote()),
      debugLabel: 'customers.insert',
    );
    if (synced) {
      db.box<Customer>().put(
        saved.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    return id;
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
    final db = await _dbHelper.store;
    final pending = value.copyWith(
      updatedAt: SyncTimestamps.forUpdate(),
      isSynced: false,
    );
    final updated = db.runInTransaction(TxMode.write, () {
      if (db.box<Customer>().get(pending.id!) == null) return 0;
      db.box<Customer>().put(pending, mode: PutMode.update);
      return 1;
    });
    if (updated == 0) return 0;
    final synced = await syncRemoteIfAvailable(
      (client) => client
          .from('customers')
          .update(pending.toRemote())
          .eq('id', pending.uuid),
      debugLabel: 'customers.update',
    );
    if (synced) {
      db.box<Customer>().put(
        pending.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    return 1;
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.store;
    final customer = db.box<Customer>().get(id);
    if (customer == null || customer.isDeleted) return 0;

    final sales = db
        .box<Sale>()
        .query(Sale_.customerId.equals(id).and(Sale_.isDeleted.equals(false)))
        .build();
    final saleIds = sales.find().map((sale) => sale.id!).toList();
    sales.close();

    final salesRepository = SaleRepository(dbHelper: _dbHelper);
    for (final saleId in saleIds) {
      await salesRepository.deleteSale(saleId);
    }

    final now = DateTime.now();
    final marked = db.runInTransaction(TxMode.write, () {
      final current = db.box<Customer>().get(id);
      if (current == null || current.isDeleted) return 0;
      db.box<Customer>().put(
        current.copyWith(isDeleted: true, isSynced: false, updatedAt: now),
        mode: PutMode.update,
      );
      return 1;
    });
    if (marked == 0) return 0;
    final deleted = db.box<Customer>().get(id);
    if (deleted == null || deleted.uuid.isEmpty) return 1;
    final synced = await syncRemoteIfAvailable(
      (client) => client
          .from('customers')
          .update(remoteDeletionStamp(now))
          .eq('id', deleted.uuid),
      debugLabel: 'customers.delete',
    );
    if (synced) {
      db.box<Customer>().put(
        deleted.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    return 1;
  }

  Future<void> pushUnsynced() async {
    final db = await _dbHelper.store;
    final query = db
        .box<Customer>()
        .query(Customer_.isSynced.equals(false))
        .build();
    List<Customer> pending;
    try {
      pending = query.find();
    } finally {
      query.close();
    }
    for (final customer in pending) {
      var synced = false;
      if (customer.uuid.isNotEmpty) {
        try {
          if (customer.isDeleted) {
            await Supabase.instance.client
                .from('customers')
                .update(remoteDeletionStamp(DateTime.now()))
                .eq('id', customer.uuid);
          } else {
            await Supabase.instance.client
                .from('customers')
                .upsert(customer.toRemote());
          }
          synced = true;
        } catch (_) {
          synced = false;
        }
      }
      if (!synced) continue;
      db.box<Customer>().put(
        customer.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
  }

  Future<void> pullSince(DateTime since) async {
    final iso = since.toUtc().toIso8601String();
    debugPrint('[CustomerRepository.pullSince] since=$iso');
    final List<dynamic> rows;
    try {
      rows = await Supabase.instance.client
          .from('customers')
          .select()
          .gt('updated_at', iso);
    } catch (e, stackTrace) {
      debugPrint('[CustomerRepository.pullSince] erro ao buscar: $e');
      debugPrint('$stackTrace');
      return;
    }
    debugPrint('[CustomerRepository.pullSince] ${rows.length} registro(s) remoto(s)');
    final db = await _dbHelper.store;
    var merged = 0;
    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final remote = Customer.fromMap(raw);
      final existing = findCustomerByUuid(db, remote.uuid);
      final mergedCustomer = remote.copyWith(id: existing?.id, isSynced: true);
      db.box<Customer>().put(
        mergedCustomer,
        mode: existing == null ? PutMode.put : PutMode.update,
      );
      merged++;
    }
    debugPrint('[CustomerRepository.pullSince] $merged cliente(s) mesclado(s)');
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/payment_model.dart';
import '../model/sale_model.dart';
import '../sync_entity_lookup.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper;
  PaymentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerPayment(Payment value) async {
    final db = await _dbHelper.store;
    if (db.box<Sale>().get(value.saleId) == null) {
      throw StateError('Venda não encontrada.');
    }
    bool isSynced = true;
    try {
      await Supabase.instance.client.from('payments').insert(value.toMap());
    } catch (_) {
      isSynced = false;
    }
    final valueAfterSync = value.copyWith(isSynced: isSynced);
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Sale>().get(valueAfterSync.saleId) == null) {
        throw StateError('Venda não encontrada.');
      }
      return db.box<Payment>().put(valueAfterSync);
    });
  }

  Future<Payment?> getPaymentById(int id) async {
    final payment = (await _dbHelper.store).box<Payment>().get(id);
    if (payment == null || payment.isDeleted) return null;
    return payment;
  }

  Future<List<Payment>> getAllPayments() async {
    final query = (await _dbHelper.store)
        .box<Payment>()
        .query(Payment_.isDeleted.equals(false))
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
  Future<int> updatePayment(Payment value) async {
    if (value.id == null || value.id == 0) {
      throw ArgumentError('ID obrigatório para atualizar.');
    }
    bool isSynced = true;
    try {
      await Supabase.instance.client
          .from('payments')
          .update(value.toMap())
          .eq('id', value.uuid);
    } catch (_) {
      isSynced = false;
    }
    final valueAfterSync = value.copyWith(isSynced: isSynced);
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Payment>().get(valueAfterSync.id!) == null) return 0;
      if (db.box<Sale>().get(valueAfterSync.saleId) == null) {
        throw StateError('Venda não encontrada.');
      }
      db.box<Payment>().put(valueAfterSync, mode: PutMode.update);
      return 1;
    });
  }

  Future<List<Payment>> getPaymentsBySaleId(int saleId) async {
    final db = await _dbHelper.store;
    final query = db
        .box<Payment>()
        .query(
          Payment_.saleId.equals(saleId).and(Payment_.isDeleted.equals(false)),
        )
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<double> getPaymentsBySaleIdAmount(int saleId) async =>
      (await getPaymentsBySaleId(saleId))
          .fold<double>(0, (sum, p) => sum + p.amount);

  Future<Map<int, double>> getPaymentTotalsBySaleIds(List<int> saleIds) async {
    if (saleIds.isEmpty) return {};
    final db = await _dbHelper.store;
    final query = db
        .box<Payment>()
        .query(
          Payment_.saleId
              .oneOf(saleIds)
              .and(Payment_.isDeleted.equals(false)),
        )
        .build();
    try {
      final totals = <int, double>{};
      for (final p in query.find()) {
        totals.update(
          p.saleId,
          (sum) => sum + p.amount,
          ifAbsent: () => p.amount,
        );
      }
      return totals;
    } finally {
      query.close();
    }
  }

  Future<int> deletePayment(int id) async {
    final db = await _dbHelper.store;
    final payment = db.box<Payment>().get(id);
    if (payment == null || payment.isDeleted) return 0;

    var synced = false;
    if (payment.uuid.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('payments')
            .update({'is_deleted': true})
            .eq('id', payment.uuid);
        synced = true;
      } catch (_) {
        synced = false;
      }
    }

    return db.runInTransaction(TxMode.write, () {
      final current = db.box<Payment>().get(id);
      if (current == null || current.isDeleted) return 0;
      db.box<Payment>().put(
        current.copyWith(isDeleted: true, isSynced: synced),
        mode: PutMode.update,
      );
      return 1;
    });
  }

  Future<void> pushUnsynced() async {
    final db = await _dbHelper.store;
    final query = db.box<Payment>().query(Payment_.isSynced.equals(false)).build();
    List<Payment> pending;
    try {
      pending = query.find();
    } finally {
      query.close();
    }
    for (final payment in pending) {
      var synced = false;
      if (payment.uuid.isNotEmpty) {
        try {
          if (payment.isDeleted) {
            await Supabase.instance.client
                .from('payments')
                .update({'is_deleted': true})
                .eq('id', payment.uuid);
          } else {
            final sale = db.box<Sale>().get(payment.saleId);
            final payload = payment.toMap()
              ..remove('id')
              ..['id'] = payment.uuid
              ..['sale_id'] = sale?.uuid ?? '';
            await Supabase.instance.client.from('payments').upsert(payload);
          }
          synced = true;
        } catch (_) {
          synced = false;
        }
      }
      if (!synced) continue;
      db.box<Payment>().put(payment.copyWith(isSynced: true), mode: PutMode.update);
    }
  }

  Future<void> pullSince(DateTime since) async {
    final iso = since.toUtc().toIso8601String();
    final List<dynamic> rows;
    try {
      rows = await Supabase.instance.client
          .from('payments')
          .select()
          .gt('date', iso);
    } catch (_) {
      return;
    }
    final db = await _dbHelper.store;
    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final saleUuid = raw['sale_id'] as String? ?? '';
      final sale = findSaleByUuid(db, saleUuid);
      if (sale?.id == null) continue;
      final uuid = (raw['id'] as String?) ?? '';
      if (uuid.isEmpty) continue;
      final existing = findPaymentByUuid(db, uuid);
      final map = Map<String, dynamic>.from(raw)..remove('id');
      map['uuid'] = uuid;
      map['sale_id'] = sale!.id;
      final remote = Payment.fromMap(map);
      final merged = remote.copyWith(id: existing?.id, isSynced: true);
      db.box<Payment>().put(
        merged,
        mode: existing == null ? PutMode.put : PutMode.update,
      );
    }
  }
}

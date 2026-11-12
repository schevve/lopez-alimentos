import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/installment_model.dart';
import '../model/sale_model.dart';
import '../sync_entity_lookup.dart';

class InstallmentRepository {
  final DatabaseHelper _dbHelper;
  InstallmentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerInstallment(Installment value) async {
    final db = await _dbHelper.store;
    final sale = db.box<Sale>().get(value.saleId);
    if (sale == null || sale.isDeleted) {
      throw StateError('Venda não encontrada.');
    }
    final installment = value.saleUuid.isEmpty
        ? value.copyWith(saleUuid: sale.uuid)
        : value;
    bool isSynced = true;
    try {
      await Supabase.instance.client
          .from('installments')
          .insert(installment.toRemote());
      await Supabase.instance.client
          .from('sales')
          .update({
            'amount_paid': sale.amountPaid + installment.amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sale.uuid);
    } catch (_) {
      isSynced = false;
    }
    final valueAfterSync = installment.copyWith(isSynced: isSynced);
    return db.runInTransaction(TxMode.write, () {
      final currentSale = db.box<Sale>().get(valueAfterSync.saleId);
      if (currentSale == null || currentSale.isDeleted) {
        throw StateError('Venda não encontrada.');
      }
      db.box<Sale>().put(
        currentSale.copyWith(
          amountPaid: currentSale.amountPaid + valueAfterSync.amount,
          updatedAt: DateTime.now(),
          isSynced: isSynced && currentSale.isSynced,
        ),
        mode: PutMode.update,
      );
      return db.box<Installment>().put(valueAfterSync);
    });
  }

  Future<Installment?> getInstallmentById(int id) async {
    final installment = (await _dbHelper.store).box<Installment>().get(id);
    if (installment == null || installment.isDeleted) return null;
    return installment;
  }

  Future<List<Installment>> getAllInstallments() async {
    final query = (await _dbHelper.store)
        .box<Installment>()
        .query(Installment_.isDeleted.equals(false))
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<int> updateInstallment(Installment value) async {
    if (value.id == null || value.id == 0) {
      throw ArgumentError('ID obrigatório para atualizar.');
    }
    bool isSynced = true;
    try {
      await Supabase.instance.client
          .from('installments')
          .update(value.toRemote())
          .eq('id', value.uuid);
    } catch (_) {
      isSynced = false;
    }
    final valueAfterSync = value.copyWith(isSynced: isSynced);
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Installment>().get(valueAfterSync.id!) == null) return 0;
      if (db.box<Sale>().get(valueAfterSync.saleId) == null) {
        throw StateError('Venda não encontrada.');
      }
      db.box<Installment>().put(valueAfterSync, mode: PutMode.update);
      return 1;
    });
  }

  Future<List<Installment>> getInstallmentsBySaleId(int saleId) async {
    final db = await _dbHelper.store;
    final query = db
        .box<Installment>()
        .query(
          Installment_.saleId
              .equals(saleId)
              .and(Installment_.isDeleted.equals(false)),
        )
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<double> paidAmountBySaleId(int saleId) async =>
      (await getInstallmentsBySaleId(saleId))
          .where((installment) => installment.isPaid)
          .fold<double>(0, (sum, installment) => sum + installment.amount);

  Future<Map<int, double>> paidTotalsBySaleIds(List<int> saleIds) async {
    if (saleIds.isEmpty) return {};
    final db = await _dbHelper.store;
    final query = db
        .box<Installment>()
        .query(
          Installment_.saleId
              .oneOf(saleIds)
              .and(Installment_.isDeleted.equals(false)),
        )
        .build();
    try {
      final totals = <int, double>{};
      for (final installment in query.find()) {
        if (!installment.isPaid) continue;
        totals.update(
          installment.saleId,
          (sum) => sum + installment.amount,
          ifAbsent: () => installment.amount,
        );
      }
      return totals;
    } finally {
      query.close();
    }
  }

  Future<int> deleteInstallment(int id) async {
    final db = await _dbHelper.store;
    final installment = db.box<Installment>().get(id);
    if (installment == null || installment.isDeleted) return 0;

    var synced = false;
    if (installment.uuid.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('installments')
            .update({
              'is_deleted': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', installment.uuid);
        synced = true;
      } catch (_) {
        synced = false;
      }
    }

    return db.runInTransaction(TxMode.write, () {
      final current = db.box<Installment>().get(id);
      if (current == null || current.isDeleted) return 0;
      db.box<Installment>().put(
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

  Future<void> pushUnsynced() async {
    final db = await _dbHelper.store;
    final query =
        db.box<Installment>().query(Installment_.isSynced.equals(false)).build();
    List<Installment> pending;
    try {
      pending = query.find();
    } finally {
      query.close();
    }
    for (final installment in pending) {
      var synced = false;
      if (installment.uuid.isNotEmpty) {
        try {
          if (installment.isDeleted) {
            await Supabase.instance.client
                .from('installments')
                .update({
                  'is_deleted': true,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', installment.uuid);
          } else {
            await Supabase.instance.client
                .from('installments')
                .upsert(installment.toRemote());
          }
          synced = true;
        } catch (_) {
          synced = false;
        }
      }
      if (!synced) continue;
      db.box<Installment>().put(
        installment.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
  }

  Future<void> pullSince(DateTime since) async {
    final iso = since.toUtc().toIso8601String();
    final List<dynamic> rows;
    try {
      rows = await Supabase.instance.client
          .from('installments')
          .select()
          .gt('updated_at', iso);
    } catch (_) {
      return;
    }
    final db = await _dbHelper.store;
    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final remote = Installment.fromMap(raw);
      if (remote.saleUuid.isEmpty) continue;
      final sale = findSaleByUuid(db, remote.saleUuid);
      if (sale?.id == null) continue;
      final existing = findInstallmentByUuid(db, remote.uuid);
      final merged = remote.copyWith(
        id: existing?.id,
        saleId: sale!.id!,
        saleUuid: sale.uuid,
        isSynced: true,
      );
      db.box<Installment>().put(
        merged,
        mode: existing == null ? PutMode.put : PutMode.update,
      );
    }
  }
}

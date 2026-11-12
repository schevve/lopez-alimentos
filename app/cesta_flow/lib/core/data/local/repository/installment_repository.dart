import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/installment_model.dart';
import '../model/sale_model.dart';

class InstallmentRepository {
  final DatabaseHelper _dbHelper;
  InstallmentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerInstallment(Installment value) async {
    final db = await _dbHelper.store;
    final sale = db.box<Sale>().get(value.saleId);
    if (sale == null) {
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
      if (currentSale == null) {
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

  Future<Installment?> getInstallmentById(int id) async =>
      (await _dbHelper.store).box<Installment>().get(id);
  Future<List<Installment>> getAllInstallments() async =>
      (await _dbHelper.store).box<Installment>().getAll();

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
        .query(Installment_.saleId.equals(saleId))
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
        .query(Installment_.saleId.oneOf(saleIds))
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

  Future<int> deleteInstallment(int id) async =>
      (await _dbHelper.store).box<Installment>().remove(id) ? 1 : 0;
}

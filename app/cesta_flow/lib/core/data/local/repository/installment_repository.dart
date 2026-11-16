import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/installment_model.dart';
import '../model/sale_model.dart';
import '../sync_entity_lookup.dart';
import 'sale_repository.dart';

class InstallmentRepository {
  final DatabaseHelper _dbHelper;
  InstallmentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> createInstallment(Installment value) async {
    if (_isPaid(value)) {
      throw ArgumentError('Parcela planejada não pode estar quitada.');
    }
    if (value.paidAmount != 0) {
      throw ArgumentError('Parcela planejada não pode ter valor pago.');
    }
    final db = await _dbHelper.store;
    final sale = db.box<Sale>().get(value.saleId);
    if (sale == null || sale.isDeleted) {
      throw StateError('Venda não encontrada.');
    }
    final installment = value.saleUuid.isEmpty
        ? value.copyWith(saleUuid: sale.uuid)
        : value;
    var isSynced = true;
    try {
      await Supabase.instance.client
          .from('installments')
          .insert(installment.toRemote());
    } catch (_) {
      isSynced = false;
    }
    final valueAfterSync = installment.copyWith(isSynced: isSynced);
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Sale>().get(valueAfterSync.saleId) == null) {
        throw StateError('Venda não encontrada.');
      }
      return db.box<Installment>().put(valueAfterSync);
    });
  }

  Future<void> createPlannedInstallmentsForSale({
    required int saleId,
    required int count,
    required double totalPrice,
    required DateTime firstDueDate,
  }) async {
    if (count < 1 || count > 3) {
      throw ArgumentError('Quantidade de parcelas deve ser entre 1 e 3.');
    }
    if (totalPrice <= 0) {
      throw ArgumentError('Valor total inválido para parcelas.');
    }
    final expectedAmounts = _splitExpectedAmounts(totalPrice, count);
    for (var index = 0; index < count; index++) {
      final dueDate = DateTime(
        firstDueDate.year,
        firstDueDate.month + index,
        firstDueDate.day,
      );
      await createInstallment(
        Installment(
          uuid: const Uuid().v4(),
          saleId: saleId,
          expectedAmount: expectedAmounts[index],
          dueDate: dueDate,
        ),
      );
    }
  }

  List<double> _splitExpectedAmounts(double total, int count) {
    final unitCents = (total * 100).round() ~/ count;
    final amounts = List<double>.filled(count, unitCents / 100);
    final assigned = unitCents * count / 100;
    amounts[count - 1] += total - assigned;
    return amounts;
  }

  Future<int> registerPayment({
    required int saleId,
    required double amount,
    String? paymentMethod,
    DateTime? paymentDate,
  }) async {
    final db = await _dbHelper.store;
    final sale = db.box<Sale>().get(saleId);
    if (sale == null || sale.isDeleted) {
      throw StateError('Venda não encontrada.');
    }
    SaleRepository.validatePaymentAmount(sale, amount);

    var installment = await _nextUnpaidInstallment(saleId);
    if (installment == null) {
      final remaining = SaleRepository.remainingBalance(sale);
      if (remaining <= 0) {
        throw StateError('Venda já está quitada.');
      }
      final planUuid = const Uuid().v4();
      await createInstallment(
        Installment(
          uuid: planUuid,
          saleId: saleId,
          expectedAmount: remaining,
        ),
      );
      installment = await _nextUnpaidInstallment(saleId);
      if (installment == null) {
        throw StateError('Não foi possível criar parcela para o pagamento.');
      }
    }

    final paidAt = paymentDate ?? DateTime.now();
    final settled = installment.copyWith(
      paidAmount: amount,
      paymentDate: paidAt,
      paymentMethod: paymentMethod,
      updatedAt: paidAt,
    );

    var isSynced = true;
    try {
      await Supabase.instance.client
          .from('installments')
          .update(settled.toRemote())
          .eq('id', settled.uuid);
      await Supabase.instance.client
          .from('sales')
          .update({
            'amount_paid': sale.amountPaid + amount,
            'updated_at': paidAt.toIso8601String(),
          })
          .eq('id', sale.uuid);
    } catch (_) {
      isSynced = false;
    }

    final settledAfterSync = settled.copyWith(isSynced: isSynced);
    final installmentId = db.runInTransaction(TxMode.write, () {
      final currentSale = db.box<Sale>().get(saleId);
      if (currentSale == null || currentSale.isDeleted) {
        throw StateError('Venda não encontrada.');
      }
      if (db.box<Installment>().get(settledAfterSync.id!) == null) {
        throw StateError('Parcela não encontrada.');
      }
      db.box<Sale>().put(
        currentSale.copyWith(
          amountPaid: currentSale.amountPaid + amount,
          updatedAt: paidAt,
          isSynced: isSynced && currentSale.isSynced,
        ),
        mode: PutMode.update,
      );
      db.box<Installment>().put(settledAfterSync, mode: PutMode.update);
      return settledAfterSync.id!;
    });

    final saleAfterPayment = db.box<Sale>().get(saleId);
    if (saleAfterPayment != null &&
        SaleRepository.isSaleFullyPaid(saleAfterPayment)) {
      await _cancelRemainingUnpaidInstallments(saleId);
    }
    return installmentId;
  }

  bool _isPaid(Installment installment) => installment.paymentDate != null;

  Future<Installment?> _nextUnpaidInstallment(int saleId) async {
    final installments = await getInstallmentsBySaleId(saleId);
    final pending =
        installments.where((item) => !_isPaid(item)).toList()
          ..sort((a, b) {
            final dueA = a.dueDate;
            final dueB = b.dueDate;
            if (dueA == null && dueB == null) {
              return a.createdAt.compareTo(b.createdAt);
            }
            if (dueA == null) return 1;
            if (dueB == null) return -1;
            final dueCompare = dueA.compareTo(dueB);
            if (dueCompare != 0) return dueCompare;
            return a.createdAt.compareTo(b.createdAt);
          });
    if (pending.isEmpty) return null;
    return pending.first;
  }

  Future<void> _cancelRemainingUnpaidInstallments(int saleId) async {
    final unpaid = (await getInstallmentsBySaleId(saleId))
        .where((item) => !_isPaid(item));
    for (final installment in unpaid) {
      final id = installment.id;
      if (id == null) continue;
      await deleteInstallment(id);
    }
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
          .where((installment) => _isPaid(installment))
          .fold<double>(0, (sum, installment) => sum + installment.paidAmount);

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
        if (!_isPaid(installment)) continue;
        totals.update(
          installment.saleId,
          (sum) => sum + installment.paidAmount,
          ifAbsent: () => installment.paidAmount,
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
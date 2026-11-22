import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/installment_due_date.dart';
import '../../../../objectbox.g.dart';
import '../../remote/sync_remote_if_available.dart';
import '../db_helper.dart';
import '../model/installment_model.dart';
import '../model/sale_model.dart';
import '../remote_deletion.dart';
import '../sync_timestamps.dart';
import '../sync_entity_lookup.dart';
import 'customer_score_service.dart';
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
    final withSale = value.saleUuid.isEmpty
        ? value.copyWith(saleUuid: sale.uuid)
        : value;
    final installment = withSale.copyWith(
      updatedAt: SyncTimestamps.forCreate(
        withSale.createdAt,
        withSale.updatedAt,
      ),
      isSynced: false,
    );
    final id = db.runInTransaction(TxMode.write, () {
      if (db.box<Sale>().get(installment.saleId) == null) {
        throw StateError('Venda não encontrada.');
      }
      return db.box<Installment>().put(installment);
    });
    final saved = installment.copyWith(id: id);
    final synced = await syncRemoteIfAvailable(
      (client) => client.from('installments').insert(saved.toRemote()),
      debugLabel: 'installments.insert',
    );
    if (synced) {
      db.box<Installment>().put(
        saved.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    return id;
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
    DateTime? lastDueDate;
    for (var index = 0; index < count; index++) {
      final dueDate = nextInstallmentDueDate(
        saleDate: firstDueDate,
        lastDueDate: lastDueDate,
      );
      lastDueDate = dueDate;
      await createInstallment(
        Installment(
          uuid: const Uuid().v4(),
          saleId: saleId,
          expectedAmount: expectedAmounts[index],
          dueDate: dueDate,
        ),
      );
    }
    await _recalculateCustomerScore(saleId);
  }

  Future<void> _recalculateCustomerScore(int saleId) async {
    final sale = (await _dbHelper.store).box<Sale>().get(saleId);
    if (sale == null || sale.isDeleted) return;
    await CustomerScoreService(dbHelper: _dbHelper).recalculate(sale.customerId);
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
      final existing = await getInstallmentsBySaleId(saleId);
      await createInstallment(
        Installment(
          uuid: planUuid,
          saleId: saleId,
          expectedAmount: remaining,
          dueDate: nextInstallmentDueDate(
            saleDate: sale.createdAt,
            lastDueDate: latestInstallmentDueDate(
              existing.map((item) => item.dueDate),
            ),
          ),
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

    final written = db.runInTransaction(TxMode.write, () {
      final currentSale = db.box<Sale>().get(saleId);
      if (currentSale == null || currentSale.isDeleted) {
        throw StateError('Venda não encontrada.');
      }
      if (db.box<Installment>().get(settled.id!) == null) {
        throw StateError('Parcela não encontrada.');
      }
      final salePending = currentSale.copyWith(
        amountPaid: currentSale.amountPaid + amount,
        updatedAt: paidAt,
        isSynced: false,
      );
      final installmentPending = settled.copyWith(isSynced: false);
      db.box<Sale>().put(salePending, mode: PutMode.update);
      db.box<Installment>().put(installmentPending, mode: PutMode.update);
      return (sale: salePending, installment: installmentPending);
    });
    final synced = await syncRemoteIfAvailable((client) async {
      await client
          .from('installments')
          .update(written.installment.toRemote())
          .eq('id', written.installment.uuid);
      await client
          .from('sales')
          .update(written.sale.toRemote())
          .eq('id', written.sale.uuid);
    }, debugLabel: 'registerPayment');
    if (synced) {
      db.box<Installment>().put(
        written.installment.copyWith(isSynced: true),
        mode: PutMode.update,
      );
      db.box<Sale>().put(
        written.sale.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    final installmentId = written.installment.id!;

    final saleAfterPayment = db.box<Sale>().get(saleId);
    if (saleAfterPayment != null &&
        SaleRepository.isSaleFullyPaid(saleAfterPayment)) {
      await _cancelRemainingUnpaidInstallments(saleId);
    } else if (saleAfterPayment != null) {
      await _ensureOpenInstallment(saleAfterPayment);
    }
    await _recalculateCustomerScore(saleId);
    return installmentId;
  }

  /// Cria a parcela seguinte quando a venda continua em aberto e não há parcela
  /// pendente. O vencimento fica fixo: um mês após a última parcela.
  Future<void> _ensureOpenInstallment(Sale sale) async {
    final saleId = sale.id;
    if (saleId == null) return;
    if (await _nextUnpaidInstallment(saleId) != null) return;
    final remaining = SaleRepository.remainingBalance(sale);
    if (remaining <= 0) return;
    final existing = await getInstallmentsBySaleId(saleId);
    await createInstallment(
      Installment(
        uuid: const Uuid().v4(),
        saleId: saleId,
        expectedAmount: remaining,
        dueDate: nextInstallmentDueDate(
          saleDate: sale.createdAt,
          lastDueDate: latestInstallmentDueDate(
            existing.map((item) => item.dueDate),
          ),
        ),
      ),
    );
  }

  bool _isPaid(Installment installment) => installment.paymentDate != null;

  List<Installment> _sortedUnpaidInstallments(List<Installment> installments) {
    final pending = installments.where((item) => !_isPaid(item)).toList()
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
    return pending;
  }

  List<Installment> _sortedPaidInstallments(List<Installment> installments) {
    final paid = installments.where(_isPaid).toList()
      ..sort((a, b) {
        final payA = a.paymentDate;
        final payB = b.paymentDate;
        if (payA == null && payB == null) {
          return b.createdAt.compareTo(a.createdAt);
        }
        if (payA == null) return 1;
        if (payB == null) return -1;
        final payCompare = payB.compareTo(payA);
        if (payCompare != 0) return payCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
    return paid;
  }

  /// Grava a visita indicada na próxima parcela em aberto, sem alterar o vencimento.
  Future<void> indicateNextPaymentDate({
    required int saleId,
    required DateTime indicatedDate,
  }) async {
    final next = await _nextUnpaidInstallment(saleId);
    if (next == null) return;
    await updateInstallment(
      next.copyWith(
        indicatedPaymentDate: indicatedDate,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<Installment?> _nextUnpaidInstallment(int saleId) async {
    final pending = _sortedUnpaidInstallments(
      await getInstallmentsBySaleId(saleId),
    );
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

  /// Parcelas não quitadas, ordenadas por data prevista de pagamento,
  /// excluindo vendas excluídas.
  Future<List<Installment>> getUnpaidInstallments() async {
    final db = await _dbHelper.store;
    final saleBox = db.box<Sale>();
    final installments = await getAllInstallments();
    final activeUnpaid = installments.where((installment) {
      if (_isPaid(installment)) return false;
      final sale = saleBox.get(installment.saleId);
      return sale != null && !sale.isDeleted;
    });
    return _sortedUnpaidInstallments(activeUnpaid.toList());
  }

  /// Parcelas em aberto primeiro, depois quitadas (mais recentes primeiro),
  /// excluindo vendas excluídas — para a lista da tela inicial.
  Future<List<Installment>> getInstallmentsForDashboard() async {
    final db = await _dbHelper.store;
    final saleBox = db.box<Sale>();
    final installments = await getAllInstallments();
    final active = installments.where((installment) {
      final sale = saleBox.get(installment.saleId);
      return sale != null && !sale.isDeleted;
    }).toList();
    final unpaid = _sortedUnpaidInstallments(active);
    final paid = _sortedPaidInstallments(active);
    return [...unpaid, ...paid];
  }

  /// Totais para os cards de métricas da tela inicial.
  Future<({double estimatedReceiptsToday, int overdueCount})>
      getPaymentMetricsForDashboard() async {
    final db = await _dbHelper.store;
    final saleBox = db.box<Sale>();
    final installments = await getAllInstallments();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var estimatedReceiptsToday = 0.0;
    var overdueCount = 0;

    for (final installment in installments) {
      if (_isPaid(installment)) continue;
      final sale = saleBox.get(installment.saleId);
      if (sale == null || sale.isDeleted) continue;

      final indicated = installment.indicatedPaymentDate;
      if (indicated != null) {
        final indicatedDay = DateTime(
          indicated.year,
          indicated.month,
          indicated.day,
        );
        if (indicatedDay == today) {
          estimatedReceiptsToday += installment.expectedAmount;
        }
      }

      final due = installment.dueDate;
      if (due == null) continue;
      final dueDay = DateTime(due.year, due.month, due.day);
      if (dueDay.isBefore(today)) {
        overdueCount++;
      }
    }

    return (
      estimatedReceiptsToday: estimatedReceiptsToday,
      overdueCount: overdueCount,
    );
  }

  Future<int> updateInstallment(Installment value) async {
    if (value.id == null || value.id == 0) {
      throw ArgumentError('ID obrigatório para atualizar.');
    }
    final db = await _dbHelper.store;
    final current = db.box<Installment>().get(value.id!);
    if (current == null || current.isDeleted) return 0;
    final pending = value.copyWith(
      dueDate: current.dueDate ?? value.dueDate,
      paymentDate: current.paymentDate ?? value.paymentDate,
      updatedAt: SyncTimestamps.forUpdate(),
      isSynced: false,
    );
    final updated = db.runInTransaction(TxMode.write, () {
      if (db.box<Installment>().get(pending.id!) == null) return 0;
      if (db.box<Sale>().get(pending.saleId) == null) {
        throw StateError('Venda não encontrada.');
      }
      db.box<Installment>().put(pending, mode: PutMode.update);
      return 1;
    });
    if (updated == 0) return 0;
    final synced = await syncRemoteIfAvailable(
      (client) => client
          .from('installments')
          .update(pending.toRemote())
          .eq('id', pending.uuid),
      debugLabel: 'installments.update',
    );
    if (synced) {
      db.box<Installment>().put(
        pending.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    return 1;
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

    final now = DateTime.now();
    final marked = db.runInTransaction(TxMode.write, () {
      final current = db.box<Installment>().get(id);
      if (current == null || current.isDeleted) return 0;
      db.box<Installment>().put(
        current.copyWith(isDeleted: true, isSynced: false, updatedAt: now),
        mode: PutMode.update,
      );
      return 1;
    });
    if (marked == 0) return 0;
    final deleted = db.box<Installment>().get(id);
    if (deleted == null || deleted.uuid.isEmpty) return 1;
    final synced = await syncRemoteIfAvailable(
      (client) => client
          .from('installments')
          .update(remoteDeletionStamp(now))
          .eq('id', deleted.uuid),
      debugLabel: 'installments.delete',
    );
    if (synced) {
      db.box<Installment>().put(
        deleted.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
    return 1;
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
                .update(remoteDeletionStamp(DateTime.now()))
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
    debugPrint('[InstallmentRepository.pullSince] since=$iso');
    final List<dynamic> rows;
    try {
      rows = await Supabase.instance.client
          .from('installments')
          .select()
          .gt('updated_at', iso);
    } catch (e, stackTrace) {
      debugPrint('[InstallmentRepository.pullSince] erro ao buscar: $e');
      debugPrint('$stackTrace');
      return;
    }
    debugPrint(
      '[InstallmentRepository.pullSince] ${rows.length} registro(s) remoto(s)',
    );
    final db = await _dbHelper.store;
    var merged = 0;
    var skipped = 0;
    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final remote = Installment.fromMap(raw);
      if (remote.saleUuid.isEmpty) {
        skipped++;
        continue;
      }
      final sale = findSaleByUuid(db, remote.saleUuid);
      if (sale?.id == null) {
        skipped++;
        continue;
      }
      final existing = findInstallmentByUuid(db, remote.uuid);
      final mergedInstallment = remote.copyWith(
        id: existing?.id,
        saleId: sale!.id!,
        saleUuid: sale.uuid,
        isSynced: true,
      );
      db.box<Installment>().put(
        mergedInstallment,
        mode: existing == null ? PutMode.put : PutMode.update,
      );
      merged++;
    }
    debugPrint(
      '[InstallmentRepository.pullSince] $merged parcela(s) mesclada(s), '
      '$skipped ignorada(s)',
    );
  }
}
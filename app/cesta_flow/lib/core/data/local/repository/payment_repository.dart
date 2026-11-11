import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/customer_score_updater.dart';
import 'package:cesta_flow/core/domain/payment_allocation.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper;

  PaymentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<PaymentRegistrationResult> registerSalePayment({
    required int saleId,
    required int amountCents,
    required String method,
    required DateTime date,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final sales = await txn.query(
        'sales',
        columns: ['price', 'quantity', 'date', 'customer_id'],
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      if (sales.isEmpty) {
        throw StateError('Venda $saleId não encontrada.');
      }

      final sale = sales.first;
      final saleTotalCents =
          (((sale['price'] as num).toDouble() *
                      (sale['quantity'] as num).toInt()) *
                  100)
              .round();
      final installmentRows = await txn.query(
        'installments',
        where: 'sale_id = ?',
        whereArgs: [saleId],
        orderBy: 'number ASC, id ASC',
      );
      final paidByInstallment = <int, int>{
        for (final row in installmentRows)
          row['id'] as int:
              (((row['paid_amount'] as num?)?.toDouble() ?? 0) * 100).round(),
      };
      final paidCents = paidByInstallment.values.fold<int>(
        0,
        (total, paid) => total + paid,
      );
      final balanceCents = saleTotalCents - paidCents;
      if (amountCents > balanceCents) {
        throw PaymentExceedsBalanceException(
          paymentCents: amountCents,
          balanceCents: balanceCents,
        );
      }

      final installmentBalances = installmentRows
          .map(
            (row) => InstallmentBalance(
              id: row['id'] as int,
              number: row['number'] as int,
              amountCents: (((row['amount'] as num).toDouble()) * 100).round(),
              paidCents: paidByInstallment[row['id'] as int] ?? 0,
            ),
          )
          .toList();
      final plan = createPaymentAllocationPlan(
        saleId: saleId,
        paymentCents: amountCents,
        saleBalanceCents: balanceCents,
        installments: installmentBalances,
        saleDate: DateTime.parse(sale['date'] as String),
      );

      var newInstallmentId = 0;
      if (plan.newInstallment case final installment?) {
        newInstallmentId = await txn.insert(
          'installments',
          installment.toMap(),
        );
        paidByInstallment[newInstallmentId] = 0;
      }

      final appliedByInstallment = <int, int>{};
      for (final allocation in plan.allocations) {
        final installmentId = allocation.isForNewInstallment
            ? newInstallmentId
            : allocation.installmentId!;
        appliedByInstallment.update(
          installmentId,
          (total) => total + allocation.amountCents,
          ifAbsent: () => allocation.amountCents,
        );
      }
      for (final entry in appliedByInstallment.entries) {
        final updated = await txn.update(
          'installments',
          {
            'paid_amount':
                ((paidByInstallment[entry.key] ?? 0) + entry.value) / 100,
            'paid_at': date.toIso8601String(),
            'payment_method': method,
          },
          where: 'id = ?',
          whereArgs: [entry.key],
        );
        if (updated != 1) {
          throw StateError(
            'Parcela ${entry.key} não encontrada para atualizar.',
          );
        }
      }

      await CustomerScoreUpdater.refresh(txn, sale['customer_id'] as int);
      return PaymentRegistrationResult(
        saleTotalCents: saleTotalCents,
        paidCents: paidCents + amountCents,
        allocations: plan.allocations,
      );
    });
  }

  Future<double> getPaidTotalBySaleId(int saleId) async {
    final totals = await getPaidTotalsBySaleIds([saleId]);
    return totals[saleId] ?? 0;
  }

  Future<Map<int, double>> getPaidTotalsBySaleIds(List<int> saleIds) async {
    if (saleIds.isEmpty) return {};

    final db = await _dbHelper.database;
    final placeholders = List.filled(saleIds.length, '?').join(', ');
    final rows = await db.query(
      'installments',
      columns: ['sale_id', 'paid_amount'],
      where: 'sale_id IN ($placeholders)',
      whereArgs: saleIds,
    );
    final totalsInCents = <int, int>{};
    for (final row in rows) {
      final saleId = row['sale_id'] as int;
      final amountCents =
          ((((row['paid_amount'] as num?)?.toDouble() ?? 0)) * 100).round();
      totalsInCents.update(
        saleId,
        (total) => total + amountCents,
        ifAbsent: () => amountCents,
      );
    }
    return {
      for (final entry in totalsInCents.entries) entry.key: entry.value / 100,
    };
  }

  Future<Map<int, double>> getPaidTotalsByInstallmentIds(
    List<int> installmentIds,
  ) async {
    if (installmentIds.isEmpty) return {};

    final db = await _dbHelper.database;
    final placeholders = List.filled(installmentIds.length, '?').join(', ');
    final rows = await db.query(
      'installments',
      columns: ['id', 'paid_amount'],
      where: 'id IN ($placeholders)',
      whereArgs: installmentIds,
    );
    return {
      for (final row in rows)
        row['id'] as int: (((row['paid_amount'] as num?)?.toDouble() ?? 0)),
    };
  }
}

class PaymentRegistrationResult {
  const PaymentRegistrationResult({
    required this.saleTotalCents,
    required this.paidCents,
    required this.allocations,
  });

  final int saleTotalCents;
  final int paidCents;
  final List<PaymentAllocation> allocations;

  bool get saleIsSettled => paidCents >= saleTotalCents;
}

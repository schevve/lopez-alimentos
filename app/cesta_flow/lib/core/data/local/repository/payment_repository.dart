import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/customer_score_updater.dart';
import 'package:cesta_flow/core/data/local/model/payment_model.dart';
import 'package:cesta_flow/core/domain/payment_allocation.dart';
import 'package:sqflite/sqflite.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper;

  PaymentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerPayment(Payment payment) async {
    final result = await registerSalePayment(
      saleId: payment.saleId,
      amountCents: (payment.amount * 100).round(),
      method: payment.method,
      date: payment.date,
    );
    return result.paymentIds.first;
  }

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
      final salePayments = await txn.query(
        'payments',
        columns: ['amount'],
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final paidCents = salePayments.fold<int>(
        0,
        (total, payment) =>
            total + (((payment['amount'] as num).toDouble()) * 100).round(),
      );
      final balanceCents = saleTotalCents - paidCents;
      if (amountCents > balanceCents) {
        throw PaymentExceedsBalanceException(
          paymentCents: amountCents,
          balanceCents: balanceCents,
        );
      }

      final installmentRows = await txn.query(
        'installments',
        where: 'sale_id = ?',
        whereArgs: [saleId],
        orderBy: 'number ASC, id ASC',
      );
      final installmentPayments = await txn.query(
        'payments',
        columns: ['installment_id', 'amount'],
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final paidByInstallment = <int, int>{};
      for (final payment in installmentPayments) {
        final installmentId = payment['installment_id'] as int?;
        if (installmentId == null) continue;
        paidByInstallment.update(
          installmentId,
          (total) =>
              total + (((payment['amount'] as num).toDouble()) * 100).round(),
          ifAbsent: () =>
              (((payment['amount'] as num).toDouble()) * 100).round(),
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
      }
      final paymentIds = <int>[];
      for (final allocation in plan.allocations) {
        final installmentId = allocation.isForNewInstallment
            ? newInstallmentId
            : allocation.installmentId!;
        paymentIds.add(
          await txn.insert(
            'payments',
            Payment(
              saleId: saleId,
              installmentId: installmentId,
              method: method,
              amount: allocation.amountCents / 100,
              date: date,
            ).toMap(),
          ),
        );
      }

      await CustomerScoreUpdater.refresh(txn, sale['customer_id'] as int);
      return PaymentRegistrationResult(
        saleTotalCents: saleTotalCents,
        paidCents: paidCents + amountCents,
        allocations: plan.allocations,
        paymentIds: paymentIds,
      );
    });
  }

  Future<Payment?> getPaymentById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Payment>> getPaymentsBySaleId(int saleId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<double> getPaymentsBySaleIdAmount(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'payments',
      columns: ['amount'],
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    final totalCents = result.fold<int>(
      0,
      (total, payment) =>
          total + (((payment['amount'] as num).toDouble()) * 100).round(),
    );
    return totalCents / 100;
  }

  Future<Map<int, double>> getPaymentTotalsBySaleIds(List<int> saleIds) async {
    if (saleIds.isEmpty) {
      return {};
    }

    final db = await _dbHelper.database;
    final placeholders = List.filled(saleIds.length, '?').join(', ');
    final result = await db.query(
      'payments',
      columns: ['sale_id', 'amount'],
      where: 'sale_id IN ($placeholders)',
      whereArgs: saleIds,
    );
    final totalsInCents = <int, int>{};
    for (final row in result) {
      final saleId = row['sale_id'] as int;
      final amountCents = (((row['amount'] as num).toDouble()) * 100).round();
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

  Future<Map<int, double>> getPaymentTotalsByInstallmentIds(
    List<int> installmentIds,
  ) async {
    if (installmentIds.isEmpty) return {};

    final db = await _dbHelper.database;
    final placeholders = List.filled(installmentIds.length, '?').join(', ');
    final rows = await db.query(
      'payments',
      columns: ['installment_id', 'amount'],
      where: 'installment_id IN ($placeholders)',
      whereArgs: installmentIds,
    );
    final totalsInCents = <int, int>{};
    for (final row in rows) {
      final installmentId = row['installment_id'] as int;
      final amountCents = (((row['amount'] as num).toDouble()) * 100).round();
      totalsInCents.update(
        installmentId,
        (total) => total + amountCents,
        ifAbsent: () => amountCents,
      );
    }
    return {
      for (final entry in totalsInCents.entries) entry.key: entry.value / 100,
    };
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('payments');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<int> updatePayment(Payment payment) async {
    if (payment.id == null) {
      throw ArgumentError('Payment id cannot be null when updating.');
    }
    final db = await _dbHelper.database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }
}

class PaymentRegistrationResult {
  const PaymentRegistrationResult({
    required this.saleTotalCents,
    required this.paidCents,
    required this.allocations,
    required this.paymentIds,
  });

  final int saleTotalCents;
  final int paidCents;
  final List<PaymentAllocation> allocations;
  final List<int> paymentIds;

  bool get saleIsSettled => paidCents >= saleTotalCents;
}

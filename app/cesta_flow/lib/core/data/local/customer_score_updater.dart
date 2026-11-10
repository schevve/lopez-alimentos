import 'package:cesta_flow/core/domain/customer_score_calculator.dart';
import 'package:cesta_flow/core/domain/customer_score_data.dart';
import 'package:sqflite/sqflite.dart';

class CustomerScoreUpdater {
  static Future<void> refresh(
    DatabaseExecutor db,
    int customerId, {
    DateTime? asOf,
  }) async {
    final salesRows = await db.query(
      'sales',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date ASC, id ASC',
    );
    final saleIds = salesRows.map((row) => row['id'] as int).toList();
    final saleIdPlaceholders = List.filled(saleIds.length, '?').join(', ');
    final installmentRows = saleIds.isEmpty
        ? <Map<String, Object?>>[]
        : await db.query(
            'installments',
            where: 'sale_id IN ($saleIdPlaceholders)',
            whereArgs: saleIds,
            orderBy: 'sale_id ASC, number ASC, id ASC',
          );
    final paymentRows = saleIds.isEmpty
        ? <Map<String, Object?>>[]
        : await db.query(
            'payments',
            where: 'sale_id IN ($saleIdPlaceholders)',
            whereArgs: saleIds,
            orderBy: 'date ASC, id ASC',
          );

    final payments = paymentRows
        .map(
          (row) => CustomerScorePayment(
            id: row['id'] as int,
            installmentId: row['installment_id'] as int?,
            amountCents: (((row['amount'] as num).toDouble()) * 100).round(),
            date: DateTime.parse(row['date'] as String),
          ),
        )
        .toList();
    final paidBySale = <int, int>{};
    final paidByInstallment = <int, int>{};
    for (var index = 0; index < paymentRows.length; index++) {
      final row = paymentRows[index];
      final payment = payments[index];
      final saleId = row['sale_id'] as int;
      paidBySale.update(
        saleId,
        (total) => total + payment.amountCents,
        ifAbsent: () => payment.amountCents,
      );
      final installmentId = payment.installmentId;
      if (installmentId != null) {
        paidByInstallment.update(
          installmentId,
          (total) => total + payment.amountCents,
          ifAbsent: () => payment.amountCents,
        );
      }
    }

    final sales = salesRows
        .map(
          (row) => CustomerScoreSale(
            id: row['id'] as int,
            date: DateTime.parse(row['date'] as String),
            totalCents:
                ((((row['price'] as num).toDouble()) *
                            (row['quantity'] as num).toInt()) *
                        100)
                    .round(),
            paidCents: paidBySale[row['id'] as int] ?? 0,
          ),
        )
        .toList();
    final installments = installmentRows.map((row) {
      final id = row['id'] as int;
      final dueDate = row['due_date'] as String?;
      return CustomerScoreInstallment(
        id: id,
        saleId: row['sale_id'] as int,
        amountCents: (((row['amount'] as num).toDouble()) * 100).round(),
        paidCents: paidByInstallment[id] ?? 0,
        dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      );
    }).toList();
    final category = calculateCustomerScore(
      createCustomerScoreInput(
        sales: sales,
        installments: installments,
        payments: payments,
        asOf: asOf ?? DateTime.now(),
      ),
    );
    final updatedRows = await db.update(
      'customers',
      {'score_category': category.name},
      where: 'id = ?',
      whereArgs: [customerId],
    );
    if (updatedRows == 0) {
      throw StateError(
        'Cliente $customerId não encontrado para atualizar score.',
      );
    }
  }
}

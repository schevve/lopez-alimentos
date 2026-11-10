import 'package:cesta_flow/core/domain/customer_score_calculator.dart';

class CustomerScoreSale {
  const CustomerScoreSale({
    required this.id,
    required this.date,
    required this.totalCents,
    required this.paidCents,
  });

  final int id;
  final DateTime date;
  final int totalCents;
  final int paidCents;
}

class CustomerScoreInstallment {
  const CustomerScoreInstallment({
    required this.id,
    required this.saleId,
    required this.amountCents,
    required this.paidCents,
    required this.dueDate,
  });

  final int id;
  final int saleId;
  final int amountCents;
  final int paidCents;
  final DateTime? dueDate;
}

class CustomerScorePayment {
  const CustomerScorePayment({
    required this.id,
    required this.installmentId,
    required this.amountCents,
    required this.date,
  });

  final int id;
  final int? installmentId;
  final int amountCents;
  final DateTime date;
}

CustomerScoreInput createCustomerScoreInput({
  required List<CustomerScoreSale> sales,
  required List<CustomerScoreInstallment> installments,
  required List<CustomerScorePayment> payments,
  required DateTime asOf,
}) {
  final orderedSales = [...sales]
    ..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
  if (orderedSales.isEmpty) {
    return CustomerScoreInput(
      lastPurchaseAt: null,
      averageDelayDays: null,
      overdueInstallmentCount: 0,
      previousSalesSettled: true,
      asOf: asOf,
    );
  }

  final lastSale = orderedSales.last;
  final today = DateTime(asOf.year, asOf.month, asOf.day);
  var overdueInstallmentCount = 0;
  var totalDelayDays = 0;
  var delayedInstallmentCount = 0;

  for (final installment in installments) {
    final dueDate = installment.dueDate;
    if (dueDate == null) continue;

    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (installment.paidCents < installment.amountCents &&
        dueDay.isBefore(today)) {
      overdueInstallmentCount++;
    }

    if (installment.paidCents < installment.amountCents) continue;
    final installmentPayments =
        payments
            .where((payment) => payment.installmentId == installment.id)
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.id.compareTo(b.id);
          });
    var paidCents = 0;
    DateTime? settledAt;
    for (final payment in installmentPayments) {
      paidCents += payment.amountCents;
      if (paidCents >= installment.amountCents) {
        settledAt = payment.date;
        break;
      }
    }
    if (settledAt == null) continue;

    final settledDay = DateTime(settledAt.year, settledAt.month, settledAt.day);
    final delayDays = settledDay.difference(dueDay).inDays;
    totalDelayDays += delayDays > 0 ? delayDays : 0;
    delayedInstallmentCount++;
  }

  final previousSalesSettled = orderedSales
      .take(orderedSales.length - 1)
      .every((sale) => sale.paidCents >= sale.totalCents);

  return CustomerScoreInput(
    lastPurchaseAt: lastSale.date,
    averageDelayDays: delayedInstallmentCount == 0
        ? null
        : totalDelayDays / delayedInstallmentCount,
    overdueInstallmentCount: overdueInstallmentCount,
    previousSalesSettled: previousSalesSettled,
    asOf: asOf,
  );
}

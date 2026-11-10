import 'package:cesta_flow/core/data/local/model/installment_model.dart';

List<Installment> createInstallmentSchedule({
  required int saleId,
  required int count,
  required double totalAmount,
  required DateTime saleDate,
}) {
  if (count < 1) {
    throw ArgumentError.value(count, 'count', 'Must be greater than zero.');
  }
  if (!totalAmount.isFinite || totalAmount <= 0) {
    throw ArgumentError.value(
      totalAmount,
      'totalAmount',
      'Must be a positive finite amount.',
    );
  }

  final totalCents = (totalAmount * 100).round();
  if (totalCents < count) {
    throw ArgumentError.value(
      count,
      'count',
      'Installment count cannot exceed the amount in cents.',
    );
  }

  final baseCents = totalCents ~/ count;
  final extraCents = totalCents % count;

  return List.generate(count, (index) {
    final amountCents = baseCents + (index < extraCents ? 1 : 0);
    return Installment(
      saleId: saleId,
      number: index + 1,
      amount: amountCents / 100,
      dueDate: monthlyInstallmentDueDate(saleDate, index + 1),
    );
  });
}

DateTime monthlyInstallmentDueDate(DateTime saleDate, int installmentNumber) {
  if (installmentNumber < 1) {
    throw ArgumentError.value(
      installmentNumber,
      'installmentNumber',
      'Must be greater than zero.',
    );
  }
  final monthIndex = saleDate.month - 1 + installmentNumber;
  final targetYear = saleDate.year + monthIndex ~/ 12;
  final targetMonth = monthIndex % 12 + 1;
  final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
  return DateTime(
    targetYear,
    targetMonth,
    saleDate.day < lastDay ? saleDate.day : lastDay,
  );
}

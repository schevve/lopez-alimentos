import 'package:cesta_flow/core/domain/installment_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Divide o valor em centavos sem perder o total', () {
    final installments = createInstallmentSchedule(
      saleId: 3,
      count: 3,
      totalAmount: 100,
      saleDate: DateTime(2026, 11, 10),
    );

    expect(installments.map((installment) => installment.amount), [
      33.34,
      33.33,
      33.33,
    ]);
    expect(
      installments.fold<int>(
        0,
        (total, installment) => total + (installment.amount * 100).round(),
      ),
      10000,
    );
    expect(installments.map((installment) => installment.number), [1, 2, 3]);
  });

  test('Calcula vencimentos mensais a partir da data da venda', () {
    final installments = createInstallmentSchedule(
      saleId: 1,
      count: 3,
      totalAmount: 3,
      saleDate: DateTime(2026, 1, 31),
    );

    expect(installments.map((installment) => installment.dueDate), [
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
      DateTime(2026, 4, 30),
    ]);
  });

  test('Rejeita quantidade que não cabe nos centavos do total', () {
    expect(
      () => createInstallmentSchedule(
        saleId: 1,
        count: 101,
        totalAmount: 1,
        saleDate: DateTime(2026, 11, 10),
      ),
      throwsArgumentError,
    );
  });
}

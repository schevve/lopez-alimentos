import 'package:cesta_flow/core/domain/installment_due_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('A primeira parcela vence um mês após a venda', () {
    final saleDate = DateTime(2026, 3, 10);
    expect(
      nextInstallmentDueDate(saleDate: saleDate),
      DateTime(2026, 4, 10),
    );
  });

  test('Cada parcela seguinte vence um mês após a anterior', () {
    final saleDate = DateTime(2026, 3, 10);
    final first = nextInstallmentDueDate(saleDate: saleDate);
    final second = nextInstallmentDueDate(
      saleDate: saleDate,
      lastDueDate: first,
    );
    final third = nextInstallmentDueDate(
      saleDate: saleDate,
      lastDueDate: second,
    );

    expect(first, DateTime(2026, 4, 10));
    expect(second, DateTime(2026, 5, 10));
    expect(third, DateTime(2026, 6, 10));
  });

  test('Parcela extra vence um mês após a última, não após a venda', () {
    final saleDate = DateTime(2026, 1, 5);
    final last = DateTime(2026, 4, 5);
    expect(
      nextInstallmentDueDate(saleDate: saleDate, lastDueDate: last),
      DateTime(2026, 5, 5),
    );
    expect(
      latestInstallmentDueDate([
        DateTime(2026, 2, 5),
        null,
        DateTime(2026, 4, 5),
        DateTime(2026, 3, 5),
      ]),
      DateTime(2026, 4, 5),
    );
  });

  test('Parcelas planejadas usam a data escolhida e vencem mês a mês', () {
    expect(
      plannedInstallmentDueDates(firstDueDate: DateTime(2026, 4, 15), count: 3),
      [DateTime(2026, 4, 15), DateTime(2026, 5, 15), DateTime(2026, 6, 15)],
    );
  });
}

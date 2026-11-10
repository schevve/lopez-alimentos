import 'package:cesta_flow/core/domain/customer_score_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Calcula atraso apenas nas parcelas pagas e conta vencidas pendentes',
    () {
      final input = createCustomerScoreInput(
        sales: [
          CustomerScoreSale(
            id: 1,
            date: DateTime(2026, 9, 1),
            totalCents: 3000,
            paidCents: 1000,
          ),
        ],
        installments: [
          CustomerScoreInstallment(
            id: 11,
            saleId: 1,
            amountCents: 1000,
            paidCents: 1000,
            dueDate: DateTime(2026, 7, 1),
          ),
          CustomerScoreInstallment(
            id: 12,
            saleId: 1,
            amountCents: 1000,
            paidCents: 500,
            dueDate: DateTime(2026, 10, 1),
          ),
          CustomerScoreInstallment(
            id: 13,
            saleId: 1,
            amountCents: 1000,
            paidCents: 0,
            dueDate: DateTime(2026, 10, 1),
          ),
        ],
        payments: [
          CustomerScorePayment(
            id: 1,
            installmentId: 11,
            amountCents: 1000,
            date: DateTime(2026, 7, 4),
          ),
          CustomerScorePayment(
            id: 2,
            installmentId: 12,
            amountCents: 500,
            date: DateTime(2026, 10, 5),
          ),
        ],
        asOf: DateTime(2026, 10, 10),
      );

      expect(input.averageDelayDays, 3);
      expect(input.overdueInstallmentCount, 2);
    },
  );

  test(
    'Usa a data que completa a parcela e limita adiantamento a zero dias',
    () {
      final input = createCustomerScoreInput(
        sales: [
          CustomerScoreSale(
            id: 1,
            date: DateTime(2026, 10, 1),
            totalCents: 1000,
            paidCents: 1000,
          ),
        ],
        installments: [
          CustomerScoreInstallment(
            id: 11,
            saleId: 1,
            amountCents: 1000,
            paidCents: 1000,
            dueDate: DateTime(2026, 10, 10),
          ),
        ],
        payments: [
          CustomerScorePayment(
            id: 1,
            installmentId: 11,
            amountCents: 400,
            date: DateTime(2026, 10, 1),
          ),
          CustomerScorePayment(
            id: 2,
            installmentId: 11,
            amountCents: 600,
            date: DateTime(2026, 10, 8),
          ),
        ],
        asOf: DateTime(2026, 10, 10),
      );

      expect(input.averageDelayDays, 0);
      expect(input.overdueInstallmentCount, 0);
    },
  );

  test('Identifica vendas anteriores não quitadas', () {
    final input = createCustomerScoreInput(
      sales: [
        CustomerScoreSale(
          id: 1,
          date: DateTime(2026, 8, 1),
          totalCents: 1000,
          paidCents: 500,
        ),
        CustomerScoreSale(
          id: 2,
          date: DateTime(2026, 9, 1),
          totalCents: 1000,
          paidCents: 0,
        ),
      ],
      installments: const [],
      payments: const [],
      asOf: DateTime(2026, 10, 10),
    );

    expect(input.previousSalesSettled, isFalse);
    expect(input.lastPurchaseAt, DateTime(2026, 9, 1));
  });
}

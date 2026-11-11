import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Serializa parcela com vencimento', () {
    final dueDate = DateTime(2026, 12, 15);
    final paidAt = DateTime(2026, 12, 20, 10);
    final installment = Installment(
      id: 8,
      saleId: 3,
      number: 2,
      amount: 125.5,
      dueDate: dueDate,
      paidAmount: 125.5,
      paidAt: paidAt,
      paymentMethod: 'Pix',
    );

    final restored = Installment.fromMap(installment.toMap());
    expect(restored.id, 8);
    expect(restored.saleId, 3);
    expect(restored.number, 2);
    expect(restored.amount, 125.5);
    expect(restored.dueDate, dueDate);
    expect(restored.paidAmount, 125.5);
    expect(restored.paidAt, paidAt);
    expect(restored.paymentMethod, 'Pix');
  });

  test('Aceita parcela legada sem vencimento ou dados de pagamento', () {
    final installment = Installment.fromMap({
      'id': 1,
      'sale_id': 4,
      'number': 1,
      'amount': 80,
      'due_date': null,
    });

    expect(installment.dueDate, isNull);
    expect(installment.paidAmount, 0);
    expect(installment.paidAt, isNull);
    expect(installment.paymentMethod, isNull);
    expect(installment.toMap()['due_date'], isNull);
  });

  test('Atualiza acumulado e permite limpar dados do último recebimento', () {
    final installment = Installment(
      saleId: 4,
      number: 1,
      amount: 80,
      paidAmount: 20,
      paidAt: DateTime(2026, 11, 10),
      paymentMethod: 'Pix',
    );

    final updated = installment.copyWith(
      paidAmount: 80,
      clearPaidAt: true,
      clearPaymentMethod: true,
    );

    expect(updated.paidAmount, 80);
    expect(updated.paidAt, isNull);
    expect(updated.paymentMethod, isNull);
  });
}

import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Serializa parcela com vencimento', () {
    final dueDate = DateTime(2026, 12, 15);
    final installment = Installment(
      id: 8,
      saleId: 3,
      number: 2,
      amount: 125.5,
      dueDate: dueDate,
    );

    final restored = Installment.fromMap(installment.toMap());
    expect(restored.id, 8);
    expect(restored.saleId, 3);
    expect(restored.number, 2);
    expect(restored.amount, 125.5);
    expect(restored.dueDate, dueDate);
  });

  test('Aceita parcela legada sem vencimento', () {
    final installment = Installment.fromMap({
      'id': 1,
      'sale_id': 4,
      'number': 1,
      'amount': 80,
      'due_date': null,
    });

    expect(installment.dueDate, isNull);
    expect(installment.toMap()['due_date'], isNull);
  });
}

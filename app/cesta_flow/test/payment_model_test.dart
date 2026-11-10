import 'package:cesta_flow/core/data/local/model/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Preserva pagamentos antigos sem parcela vinculada', () {
    final payment = Payment.fromMap({
      'id': 5,
      'sale_id': 2,
      'method': 'Dinheiro',
      'amount': 40,
      'date': '2026-11-09T12:00:00.000',
    });

    expect(payment.installmentId, isNull);
    expect(Payment.fromMap(payment.toMap()).installmentId, isNull);
  });

  test('Serializa o vínculo com a parcela', () {
    final payment = Payment(
      saleId: 2,
      installmentId: 7,
      method: 'Pix',
      amount: 40,
      date: DateTime(2026, 11, 9),
    );

    expect(Payment.fromMap(payment.toMap()).installmentId, 7);
  });
}

import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/domain/customer_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final asOf = DateTime(2026, 8, 31, 12);

  CustomerScoreCategory calculate({
    DateTime? lastPurchaseAt,
    double? averageDelayDays = 0,
    int overdueInstallmentCount = 0,
    bool previousSalesSettled = true,
  }) {
    return calculateCustomerScore(
      CustomerScoreInput(
        lastPurchaseAt: lastPurchaseAt,
        averageDelayDays: averageDelayDays,
        overdueInstallmentCount: overdueInstallmentCount,
        previousSalesSettled: previousSalesSettled,
        asOf: asOf,
      ),
    );
  }

  test('Cliente sem histórico começa Amarelo', () {
    expect(calculate(lastPurchaseAt: null), CustomerScoreCategory.yellow);
  });

  test('Cliente recente, quitado e em dia fica Verde', () {
    expect(
      calculate(lastPurchaseAt: DateTime(2026, 7, 10), averageDelayDays: 3),
      CustomerScoreCategory.green,
    );
  });

  test('Atraso médio acima do limite Verde mantém Amarelo', () {
    expect(
      calculate(lastPurchaseAt: DateTime(2026, 7, 10), averageDelayDays: 4),
      CustomerScoreCategory.yellow,
    );
  });

  test('Compra fora da janela mantém Amarelo', () {
    expect(
      calculate(lastPurchaseAt: DateTime(2026, 2, 27)),
      CustomerScoreCategory.yellow,
    );
  });

  test('Vendas anteriores não quitadas mantêm Amarelo', () {
    expect(
      calculate(
        lastPurchaseAt: DateTime(2026, 7, 10),
        previousSalesSettled: false,
      ),
      CustomerScoreCategory.yellow,
    );
  });

  test('Dados de atraso indisponíveis não classificam como Verde', () {
    expect(
      calculate(lastPurchaseAt: DateTime(2026, 7, 10), averageDelayDays: null),
      CustomerScoreCategory.yellow,
    );
  });

  test('Atraso médio de 15 dias classifica como Vermelho', () {
    expect(
      calculate(lastPurchaseAt: DateTime(2026, 7, 10), averageDelayDays: 15),
      CustomerScoreCategory.red,
    );
  });

  test('Duas parcelas vencidas classificam como Vermelho', () {
    expect(
      calculate(
        lastPurchaseAt: DateTime(2026, 7, 10),
        overdueInstallmentCount: 2,
      ),
      CustomerScoreCategory.red,
    );
  });

  test('Uma parcela vencida mantém Amarelo', () {
    expect(
      calculate(
        lastPurchaseAt: DateTime(2026, 7, 10),
        overdueInstallmentCount: 1,
      ),
      CustomerScoreCategory.yellow,
    );
  });

  test('Compra na data limite de seis meses é considerada recente', () {
    expect(
      calculate(lastPurchaseAt: DateTime(2026, 2, 28)),
      CustomerScoreCategory.green,
    );
  });

  test('Compra futura não é considerada recente', () {
    expect(
      calculate(lastPurchaseAt: DateTime(2026, 9, 1)),
      CustomerScoreCategory.yellow,
    );
  });
}

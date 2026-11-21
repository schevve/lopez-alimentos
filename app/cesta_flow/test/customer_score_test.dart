import 'package:cesta_flow/core/domain/customer_score.dart';
import 'package:cesta_flow/core/domain/score_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 6, 15);

  test('Média de 1 ou 2 é boa, 3 é média e 4 ou mais cai', () {
    expect(installmentScore(1), 100);
    expect(installmentScore(2), 100);
    expect(installmentScore(3), 60);
    expect(installmentScore(4), 35);
    expect(installmentScore(5), 10);
    expect(installmentScore(6), 0);
  });

  test('Média de 4 ou mais com volume e assiduidade altos fica em 40 ou mais', () {
    final score = calculateCustomerScore(
      salePrices: List<double>.filled(6, 160),
      installmentCounts: List<int>.filled(6, 4),
      timings: [
        InstallmentTiming(
          dueDate: DateTime(2026, 6, 1),
          paymentDate: DateTime(2026, 6, 2),
        ),
      ],
      today: today,
    );

    expect(volumeScore(purchaseCount: 6, totalSpent: 960), 90);
    expect(installmentScore(4), 35);
    expect(score, 76);
    expect(score!, inInclusiveRange(40, 100));
    expect(ScoreBand.fromScore(score), ScoreBand.bom);
    expect(ScoreBand.bom.label, 'Bom');
  });

  test('Atraso com média alta de parcelas fica abaixo de 40', () {
    final score = calculateCustomerScore(
      salePrices: const [100],
      installmentCounts: const [6],
      timings: [
        InstallmentTiming(
          dueDate: DateTime(2026, 5, 1),
          paymentDate: DateTime(2026, 5, 21),
        ),
      ],
      today: today,
    );

    expect(score, 3);
    expect(score!, lessThan(ScoreBand.ruimBelow));
    expect(ScoreBand.fromScore(score), ScoreBand.ruim);
    expect(ScoreBand.ruim.label, 'Ruim');
    expect(blockedAfterScore(alreadyBlocked: false, score: score), isTrue);
  });

  test('Score fica entre 0 e 100 e é nulo sem compras', () {
    expect(
      calculateCustomerScore(
        salePrices: const [],
        installmentCounts: const [],
        timings: const [],
        today: today,
      ),
      isNull,
    );
    expect(
      calculateCustomerScore(
        salePrices: List<double>.filled(8, 2000),
        installmentCounts: List<int>.filled(8, 1),
        timings: [
          InstallmentTiming(dueDate: today, paymentDate: today),
        ],
        today: today,
      ),
      100,
    );
    expect(
      calculateCustomerScore(
        salePrices: const [1],
        installmentCounts: const [8],
        timings: [
          InstallmentTiming(
            dueDate: DateTime(2026, 1, 1),
            paymentDate: DateTime(2026, 6, 1),
          ),
        ],
        today: today,
      ),
      inInclusiveRange(0, 100),
    );
  });

  test('Parcela no prazo, futura e vencida em aberto entram como o esperado', () {
    expect(
      daysLate(
        InstallmentTiming(
          dueDate: DateTime(2026, 6, 10, 18),
          paymentDate: DateTime(2026, 6, 10, 8),
        ),
        today,
      ),
      0,
    );
    expect(
      daysLate(
        const InstallmentTiming(dueDate: null, paymentDate: null),
        today,
      ),
      isNull,
    );
    expect(
      daysLate(
        InstallmentTiming(dueDate: DateTime(2026, 6, 20)),
        today,
      ),
      isNull,
    );
    expect(
      daysLate(
        InstallmentTiming(dueDate: DateTime(2026, 6, 10)),
        today,
      ),
      5,
    );
  });

  test('Faixas e bloqueio permanente', () {
    expect(ScoreBand.fromScore(null), isNull);
    expect(ScoreBand.fromScore(40), ScoreBand.medio);
    expect(ScoreBand.medio.label, 'Médio');
    expect(ScoreBand.fromScore(70), ScoreBand.bom);
    expect(formatCustomerScore(null), 'Score não informado');
    expect(formatCustomerScore(40), 'Score: 40 · Médio');

    expect(blockedAfterScore(alreadyBlocked: false, score: null), isFalse);
    expect(blockedAfterScore(alreadyBlocked: false, score: 40), isFalse);
    expect(blockedAfterScore(alreadyBlocked: false, score: 39), isTrue);
    expect(blockedAfterScore(alreadyBlocked: true, score: 80), isTrue);
    expect(blockedAfterScore(alreadyBlocked: true, score: null), isTrue);
  });
}

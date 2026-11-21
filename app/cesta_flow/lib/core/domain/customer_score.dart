import 'dart:math' as math;

import 'score_band.dart';

/// Pesos da média final. Somam 1.
const double scoreWeightVolume = 0.25;
const double scoreWeightAssiduity = 0.45;
const double scoreWeightInstallments = 0.30;

/// Compras que saturam o fator de quantidade.
const int scorePurchasesForFull = 6;

/// Valor gasto, em reais, que satura o fator de valor.
const double scoreValueForFull = 1200;

/// Assiduidade quando ainda não há parcela vencida ou paga com vencimento.
const double scoreNeutralAssiduity = 70;

/// Pontos perdidos por dia de atraso, até zerar o fator da parcela.
const double scoreLateDayPenalty = 5;

/// Vencimento e pagamento usados só no cálculo, sem acesso ao banco.
class InstallmentTiming {
  const InstallmentTiming({this.dueDate, this.paymentDate});

  final DateTime? dueDate;
  final DateTime? paymentDate;
}

/// Score de 0 a 100, ou nulo quando não há compras.
double? calculateCustomerScore({
  required List<double> salePrices,
  required List<int> installmentCounts,
  required List<InstallmentTiming> timings,
  DateTime? today,
}) {
  if (salePrices.isEmpty) return null;
  final volume = volumeScore(
    purchaseCount: salePrices.length,
    totalSpent: salePrices.fold<double>(0, (sum, price) => sum + price),
  );
  final average = installmentCounts.isEmpty
      ? 1.0
      : installmentCounts.fold<int>(0, (sum, count) => sum + count) /
            installmentCounts.length;
  final parcels = installmentScore(average);
  final punctuality = assiduityScore(timings, today ?? DateTime.now());
  final raw =
      scoreWeightVolume * volume +
      scoreWeightAssiduity * punctuality +
      scoreWeightInstallments * parcels;
  return raw.roundToDouble().clamp(0, 100).toDouble();
}

double volumeScore({required int purchaseCount, required double totalSpent}) {
  final countScore = math.min(
    100,
    purchaseCount / scorePurchasesForFull * 100,
  );
  final valueScore = math.min(100, totalSpent / scoreValueForFull * 100);
  return (countScore + valueScore) / 2;
}

/// Até 2 é 100, 3 é 60 e cada parcela acima de 3 tira 25, até 0.
double installmentScore(double average) {
  if (average <= 2) return 100;
  if (average <= 3) return 100 - (average - 2) * 40;
  return math.max(0, 60 - (average - 3) * 25);
}

double assiduityScore(List<InstallmentTiming> timings, DateTime today) {
  final points = <double>[];
  for (final timing in timings) {
    final late = daysLate(timing, today);
    if (late == null) continue;
    points.add(math.max(0, 100 - scoreLateDayPenalty * late));
  }
  if (points.isEmpty) return scoreNeutralAssiduity;
  return points.fold<double>(0, (sum, point) => sum + point) / points.length;
}

/// Dias de atraso. Nulo quando a parcela não entra na assiduidade.
int? daysLate(InstallmentTiming timing, DateTime today) {
  final due = timing.dueDate;
  if (due == null) return null;
  final dueDay = _day(due);
  final paid = timing.paymentDate;
  if (paid != null) {
    final late = _day(paid).difference(dueDay).inDays;
    return late < 0 ? 0 : late;
  }
  final todayDay = _day(today);
  if (!dueDay.isBefore(todayDay)) return null;
  return todayDay.difference(dueDay).inDays;
}

/// Bloqueio não volta atrás. Sem score, só permanece bloqueado quem já estava.
bool blockedAfterScore({required bool alreadyBlocked, required double? score}) {
  if (alreadyBlocked) return true;
  if (score == null) return false;
  return score < ScoreBand.ruimBelow;
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

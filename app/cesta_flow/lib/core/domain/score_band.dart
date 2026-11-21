/// Faixa do score de 0 a 100. O número gravado no cliente é a fonte;
/// a interface usa só o rótulo deste enum.
enum ScoreBand {
  bom('Bom'),
  medio('Médio'),
  ruim('Ruim');

  const ScoreBand(this.label);

  final String label;

  /// Abaixo deste valor a faixa é [ruim] e o cliente passa a bloqueado.
  static const double ruimBelow = 40;

  /// A partir deste valor a faixa é [bom].
  static const double bomFrom = 70;

  static ScoreBand? fromScore(double? score) {
    if (score == null) return null;
    if (score < ruimBelow) return ScoreBand.ruim;
    if (score < bomFrom) return ScoreBand.medio;
    return ScoreBand.bom;
  }
}

/// Texto do score para cartão e ficha. Nulo continua “não informado”.
String formatCustomerScore(double? score) {
  if (score == null) return 'Score não informado';
  final band = ScoreBand.fromScore(score)!;
  final number = score == score.roundToDouble()
      ? score.toInt().toString()
      : score.toString();
  return 'Score: $number · ${band.label}';
}

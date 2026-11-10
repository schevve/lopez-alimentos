String formatCurrency(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final integerPart = parts.first;
  final buffer = StringBuffer();

  for (var index = 0; index < integerPart.length; index++) {
    final remainingDigits = integerPart.length - index;
    buffer.write(integerPart[index]);
    if (remainingDigits > 1 && remainingDigits % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},${parts.last}';
}

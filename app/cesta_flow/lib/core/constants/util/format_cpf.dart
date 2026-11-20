import 'package:flutter/services.dart';

String onlyDigits(String? value) =>
    (value ?? '').replaceAll(RegExp(r'\D'), '');

String formatCpf(String rawCpf) {
  final cpf = onlyDigits(rawCpf);
  if (cpf.length != 11) {
    return rawCpf;
  }
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
}

/// Máscara incremental de CPF (use com [FilteringTextInputFormatter.digitsOnly]).
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text;
    final buffer = StringBuffer();
    var cursor = 0;
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
      if (i < newValue.selection.extentOffset) cursor = buffer.length;
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

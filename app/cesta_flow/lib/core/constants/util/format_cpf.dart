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

/// Valida os dígitos verificadores do CPF (após normalizar para 11 dígitos).
bool isValidCpf(String? value) {
  final cpf = onlyDigits(value);
  if (cpf.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

  final digits = cpf.split('').map(int.parse).toList(growable: false);

  int verifierDigit(List<int> base, int weightStart) {
    var sum = 0;
    for (var i = 0; i < base.length; i++) {
      sum += base[i] * (weightStart - i);
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  final first = verifierDigit(digits.sublist(0, 9), 10);
  if (first != digits[9]) return false;

  final second = verifierDigit(digits.sublist(0, 10), 11);
  return second == digits[10];
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

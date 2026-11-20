import 'package:flutter/services.dart';

class FormatDate extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 8) {
      return oldValue;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FormatMoney extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final value = double.parse(digitsOnly) / 100;
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatMoneyField(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

double parseMoneyField(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  final normalized = trimmed.contains(',')
      ? trimmed.replaceAll('.', '').replaceAll(',', '.')
      : trimmed;
  return double.parse(normalized);
}

String getCurrentFormattedDate() {
  final now = DateTime.now();
  final day = now.day.toString().padLeft(2, '0');
  final month = now.month.toString().padLeft(2, '0');
  final year = now.year.toString();
  return '$day/$month/$year';
}

DateTime? parseDateField(String value) {
  final trimmed = value.trim();
  if (trimmed.length < 10) return null;
  final parts = trimmed.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

import 'package:flutter/services.dart';

class FormatPhoneNumber extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 11) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      final isMobile = digitsOnly.length > 10;
      if (!isMobile && i == 6) buffer.write('-');
      if (isMobile && i == 7) buffer.write('-');
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
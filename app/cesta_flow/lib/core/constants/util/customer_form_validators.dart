import 'package:cesta_flow/core/constants/util/format_cpf.dart';

String? validateRequired(String? value, String message) =>
    (value ?? '').trim().isEmpty ? message : null;

String? validateBirthDate(String? value) {
  final text = (value ?? '').trim();
  final parts = text.split('/');
  if (parts.length != 3) return 'Informe a data (dd/mm/aaaa).';
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null || parts[2].length != 4) {
    return 'Informe a data (dd/mm/aaaa).';
  }
  final date = DateTime(year, month, day);
  final valid = date.day == day && date.month == month && date.year == year;
  if (!valid || year < 1900 || date.isAfter(DateTime.now())) {
    return 'Informe uma data válida.';
  }
  return null;
}

String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return null;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : 'Informe um e-mail válido.';
}

String? validatePhone(String? value) {
  final length = onlyDigits(value).length;
  return length == 10 || length == 11
      ? null
      : 'Informe um telefone válido com DDD.';
}

String? validateCep(String? value) {
  if (onlyDigits(value).isEmpty) return null;
  return onlyDigits(value).length == 8 ? null : 'O CEP deve ter 8 dígitos.';
}

String? validateCpf(String? value) =>
    onlyDigits(value).length == 11 ? null : 'O CPF deve ter 11 dígitos.';

String? validateRg(String? value) {
  final digits = onlyDigits(value);
  if (digits.isEmpty) return null;
  if (digits.length < 5) return 'Informe um RG válido.';
  return null;
}

String? validateState(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  if (text.length < 2) return 'Informe a sigla ou nome do estado.';
  return null;
}
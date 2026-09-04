String formatCpf(String rawCpf) {
  final cpf = rawCpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (cpf.length != 11) {
    return rawCpf;
  }
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
}

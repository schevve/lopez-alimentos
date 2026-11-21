/// Vencimento da próxima parcela: um mês após a venda, ou um mês após a última.
DateTime nextInstallmentDueDate({
  required DateTime saleDate,
  DateTime? lastDueDate,
}) {
  final anchor = lastDueDate ?? saleDate;
  return DateTime(anchor.year, anchor.month + 1, anchor.day);
}

/// Vencimento mais recente já registrado na venda.
DateTime? latestInstallmentDueDate(Iterable<DateTime?> dueDates) {
  DateTime? latest;
  for (final dueDate in dueDates) {
    if (dueDate == null) continue;
    if (latest == null || dueDate.isAfter(latest)) latest = dueDate;
  }
  return latest;
}

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

/// Vencimentos das parcelas planejadas no registro da venda.
///
/// A primeira parcela vence exatamente em [firstDueDate] e as seguintes um mês
/// após a parcela anterior.
List<DateTime> plannedInstallmentDueDates({
  required DateTime firstDueDate,
  required int count,
}) {
  if (count < 1) return const [];
  final dueDates = <DateTime>[firstDueDate];
  for (var index = 1; index < count; index++) {
    dueDates.add(
      nextInstallmentDueDate(
        saleDate: firstDueDate,
        lastDueDate: dueDates.last,
      ),
    );
  }
  return dueDates;
}

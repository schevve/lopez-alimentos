/// Período inclusivo (dia civil) para limitar vendas, parcelas e vínculos na
/// exportação. Clientes e cestas não usam este filtro.
class ExportPeriodFilter {
  ExportPeriodFilter({required DateTime start, required DateTime end})
    : start = _dateOnly(start),
      end = _dateOnly(end) {
    if (this.start.isAfter(this.end)) {
      throw ArgumentError('A data de início não pode ser posterior à data fim.');
    }
  }

  final DateTime start;
  final DateTime end;

  /// Do dia 1 ao último dia do [reference], no fuso local.
  factory ExportPeriodFilter.calendarMonth([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    return ExportPeriodFilter(start: monthStart, end: monthEnd);
  }

  bool contains(DateTime value) {
    final day = _dateOnly(value);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
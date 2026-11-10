import 'package:cesta_flow/core/constants/customer_score_config.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';

class CustomerScoreInput {
  const CustomerScoreInput({
    required this.lastPurchaseAt,
    required this.averageDelayDays,
    required this.overdueInstallmentCount,
    required this.previousSalesSettled,
    required this.asOf,
  }) : assert(averageDelayDays == null || averageDelayDays >= 0),
       assert(overdueInstallmentCount >= 0);

  final DateTime? lastPurchaseAt;
  final double? averageDelayDays;
  final int overdueInstallmentCount;
  final bool previousSalesSettled;
  final DateTime asOf;
}

CustomerScoreCategory calculateCustomerScore(CustomerScoreInput input) {
  if (input.lastPurchaseAt == null) {
    return CustomerScoreCategory.yellow;
  }

  final averageDelay = input.averageDelayDays;
  if ((averageDelay != null &&
          averageDelay >= CustomerScoreConfig.redMinAverageDelayDays) ||
      input.overdueInstallmentCount >=
          CustomerScoreConfig.redMinOverdueInstallments) {
    return CustomerScoreCategory.red;
  }

  if (_hasRecentPurchase(input.lastPurchaseAt!, input.asOf) &&
      averageDelay != null &&
      averageDelay <= CustomerScoreConfig.greenMaxAverageDelayDays &&
      input.overdueInstallmentCount == 0 &&
      input.previousSalesSettled) {
    return CustomerScoreCategory.green;
  }

  return CustomerScoreCategory.yellow;
}

bool _hasRecentPurchase(DateTime lastPurchaseAt, DateTime asOf) {
  final today = DateTime(asOf.year, asOf.month, asOf.day);
  final purchaseDate = DateTime(
    lastPurchaseAt.year,
    lastPurchaseAt.month,
    lastPurchaseAt.day,
  );
  if (purchaseDate.isAfter(today)) {
    return false;
  }

  final monthIndex =
      today.year * 12 +
      today.month -
      1 -
      CustomerScoreConfig.greenRecentPurchaseMonths;
  final cutoffYear = monthIndex ~/ 12;
  final cutoffMonth = monthIndex % 12 + 1;
  final lastDayOfCutoffMonth = DateTime(cutoffYear, cutoffMonth + 1, 0).day;
  final cutoffDate = DateTime(
    cutoffYear,
    cutoffMonth,
    today.day < lastDayOfCutoffMonth ? today.day : lastDayOfCutoffMonth,
  );

  return !purchaseDate.isBefore(cutoffDate);
}

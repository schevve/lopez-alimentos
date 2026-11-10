import 'package:cesta_flow/core/constants/customer_score_config.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';

bool isCustomerBlocked({
  required Customer customer,
  required int openInstallmentCount,
}) {
  if (openInstallmentCount < 0) {
    throw ArgumentError.value(
      openInstallmentCount,
      'openInstallmentCount',
      'Cannot be negative.',
    );
  }

  final manualOverride = customer.manualBlockOverride;
  if (manualOverride != null) {
    return manualOverride;
  }

  if (customer.authorized) {
    return false;
  }

  return openInstallmentCount >=
      CustomerScoreConfig.automaticBlockOpenInstallments;
}

import 'package:cesta_flow/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:flutter/material.dart';

class MetricsRow extends StatelessWidget {
  final List<MetricCard> cards;
  const MetricsRow({required this.cards, super.key});

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) const SizedBox(width: _spacing),
            cards[index],
          ],
        ],
      ),
    );
  }
}

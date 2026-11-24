import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:flutter/material.dart';

const metricsPanelDecoration = BoxDecoration(
  color: AppColors.primary,
  borderRadius: BorderRadius.all(Radius.circular(22)),
  image: DecorationImage(
    image: AssetImage('assets/images/FundoComidas.png'),
    repeat: ImageRepeat.repeat,
    scale: 0.22,
    alignment: Alignment.center,
  ),
);

class MetricsPanel extends StatelessWidget {
  const MetricsPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: metricsPanelDecoration,
      child: child,
    );
  }
}

class MetricsRow extends StatelessWidget {
  final List<MetricCard> cards;
  const MetricsRow({required this.cards, super.key});

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return MetricsPanel(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(width: _spacing),
              Expanded(child: cards[index]),
            ],
          ],
        ),
      ),
    );
  }
}

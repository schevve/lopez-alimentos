import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:flutter/material.dart';

class MetricsRow extends StatelessWidget {
  final List<MetricCard> cards;
  const MetricsRow({required this.cards, super.key});

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(22)),
        image: DecorationImage(
          image: AssetImage('assets/images/FundoComidas.png'),
          repeat: ImageRepeat.repeat,
          scale: 0.22,
          alignment: Alignment.center,
        ),
      ),
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

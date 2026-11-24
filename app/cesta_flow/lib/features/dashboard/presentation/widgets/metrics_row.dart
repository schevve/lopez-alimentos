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

  /// Quantos cards por linha. Se omitido, todos ficam na mesma linha (Home).
  final int? columns;

  /// Primeiro card em linha própria; o restante usa [columns].
  final bool firstCardFullWidth;

  const MetricsRow({
    required this.cards,
    this.columns,
    this.firstCardFullWidth = false,
    super.key,
  });

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    final perRow = (columns ?? cards.length).clamp(1, 99);
    return MetricsPanel(child: _grid(perRow));
  }

  Widget _grid(int perRow) {
    if (firstCardFullWidth && cards.isNotEmpty) {
      final rest = cards.sublist(1);
      return Column(
        children: [
          _linha([cards.first]),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: _spacing),
            _stacked(rest, perRow),
          ],
        ],
      );
    }

    return _stacked(cards, perRow);
  }

  Widget _stacked(List<MetricCard> items, int perRow) {
    if (perRow >= items.length) {
      return _linha(items);
    }
    return Column(
      children: [
        for (var start = 0; start < items.length; start += perRow) ...[
          if (start > 0) const SizedBox(height: _spacing),
          _linha(
            items.sublist(
              start,
              start + perRow > items.length ? items.length : start + perRow,
            ),
            vazios: start + perRow - items.length,
          ),
        ],
      ],
    );
  }

  // Uma linha de cards com a mesma altura (igual à da Home original).
  Widget _linha(List<MetricCard> linha, {int vazios = 0}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < linha.length; i++) ...[
            if (i > 0) const SizedBox(width: _spacing),
            Expanded(child: linha[i]),
          ],
          for (var i = 0; i < vazios; i++) ...[
            const SizedBox(width: _spacing),
            const Expanded(child: SizedBox.shrink()),
          ],
        ],
      ),
    );
  }
}
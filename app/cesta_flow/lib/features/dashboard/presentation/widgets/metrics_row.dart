import 'package:flutter/material.dart';

class MetricsRow extends StatefulWidget {
  const MetricsRow({super.key});

  @override
  State<MetricsRow> createState() => _MetricsRowState();
}

class _MetricsRowState extends State<MetricsRow> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _MetricCard(
            title: 'Vendas',
            value: 'R\$ 1.200,00',
            subtitle: 'Últimos 7 dias',
            icon: Icons.shopping_cart,
            iconColor: Color(0xFF0D5C34),
          ),
          SizedBox(width: 12),
          _MetricCard(
            title: 'Clientes',
            value: '45',
            subtitle: 'Ativos',
            icon: Icons.people,
            iconColor: Color(0xFF267A48),
          ),
          SizedBox(width: 12),
          _MetricCard(
            title: 'Pendências',
            value: '3',
            subtitle: 'Atrasadas',
            icon: Icons.warning,
            iconColor: Color(0xFFC62828),
          ),
        ],
      ),
    );
  }
}

// Helper widget for metric cards
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF707070)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF202020),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF707070)),
          ),
        ],
      ),
    );
  }
}

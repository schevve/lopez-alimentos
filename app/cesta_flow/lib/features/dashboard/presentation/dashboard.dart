import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:cesta_flow/features/shared/bottom_bar.dart';
import 'package:flutter/material.dart';

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
    super.key,
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
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF202020))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
        ],
      ),
    );
  }
}

// Pill widget
class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final int? badgeCount;
  final Color? badgeColor;
  const _Pill({
    required this.label,
    this.selected = false,
    this.badgeCount,
    this.badgeColor,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF0D5C34) : Colors.white;
    final txt = selected ? Colors.white : const Color(0xFF202020);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: txt, fontSize: 14, fontWeight: FontWeight.w500)),
          if (badgeCount != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

// Client card widget
class _ClientCard extends StatelessWidget {
  final String name;
  final String scoreLabel;
  final Color scoreColor;
  final String status;
  final Color statusColor;
  final String address;
  final String distance;
  final Color distanceColor;
  final String product;
  final Color productColor;
  final String amount;
  final Color amountColor;
  const _ClientCard({
    required this.name,
    required this.scoreLabel,
    required this.scoreColor,
    required this.status,
    required this.statusColor,
    required this.address,
    required this.distance,
    required this.distanceColor,
    required this.product,
    required this.productColor,
    required this.amount,
    required this.amountColor,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 150, color: scoreColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(scoreLabel, style: TextStyle(color: scoreColor, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
                const SizedBox(height: 4),
                Text(address, style: const TextStyle(fontSize: 12, color: Color(0xFF202020))),
                const SizedBox(height: 4),
                Text(distance, style: TextStyle(color: distanceColor, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: productColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(product, style: TextStyle(color: productColor, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                Text(amount, style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
                        child: const Text('Ver Venda', style: TextStyle(color: Color(0xFF202020))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: amountColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
                        child: const Text('Receber', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color(0xFFF0FDF4),
          bottomNavigationBar: const BottomBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 14),
                // Logistics Card
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF155F38), Color(0xFF0C4D2A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "LOGÍSTICA INTELIGENTE",
                        style: TextStyle(
                          color: Color(0xFFB9D2BE),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Rota Otimizada de Hoje",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "12 paradas calculadas para menor tempo e combustível",
                        style: TextStyle(
                          color: Color(0xFFB2C8B9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7A16),
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.my_location, color: Colors.white),
                              label: const Text('Iniciar Rota no GPS'),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.map, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MetricCard(
                      title: 'A Receber',
                      value: 'R\$ 1.840',
                      subtitle: 'Hoje',
                      icon: Icons.attach_money,
                      iconColor: Color(0xFF0D5C34),
                    ),
                    _MetricCard(
                      title: 'Visitas',
                      value: '12',
                      subtitle: 'Pendentes',
                      icon: Icons.access_time,
                      iconColor: Color(0xFF2F7A4A),
                    ),
                    _MetricCard(
                      title: 'Atrasados',
                      value: '3 parc.',
                      subtitle: 'Atenção',
                      icon: Icons.error,
                      iconColor: Color(0xFFC62828),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Pill(
                      label: 'Vence Hoje',
                      selected: true,
                      badgeCount: 7,
                      badgeColor: const Color(0xFFB9D2BE),
                    ),
                    _Pill(
                      label: 'Atrasados',
                      badgeCount: 3,
                      badgeColor: const Color(0xFFC62828),
                    ),
                    _Pill(
                      label: 'Agendados',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Client Cards
                _ClientCard(
                  name: 'José Aparecido dos Santo',
                  scoreLabel: 'Score: Ruim',
                  scoreColor: const Color(0xFFFF7A16),
                  status: 'Vencida há 3 dias',
                  statusColor: const Color(0xFFC62828),
                  address: 'Av. das Palmeiras, 420 – Bloco B (Jd. América)',
                  distance: 'A 800m',
                  distanceColor: const Color(0xFF0D5C34),
                  product: 'Cesta Básica Completa Família',
                  productColor: const Color(0xFFB9D2BE),
                  amount: 'R\$ 85,00',
                  amountColor: const Color(0xFFC62828),
                ),
                const SizedBox(height: 14),
                _ClientCard(
                  name: 'Rosângela Batista',
                  scoreLabel: 'Score: Bom',
                  scoreColor: const Color(0xFF0D5C34),
                  status: 'Parcela programada para hoje',
                  statusColor: const Color(0xFF0D5C34),
                  address: 'Rua dos Pintados, 67 (Vila Nova)',
                  distance: 'Próxima da rota',
                  distanceColor: const Color(0xFF0D5C34),
                  product: 'Cesta Especial 7ª Base',
                  productColor: const Color(0xFFB9D2BE),
                  amount: 'R\$ 83,00',
                  amountColor: const Color(0xFFC62828),
                ),
                const SizedBox(height: 14),
                _ClientCard(
                  name: 'Ângelo Pereira de Souza',
                  scoreLabel: 'Score: Regular',
                  scoreColor: const Color(0xFF707070),
                  status: 'Horário comercial sugerido',
                  statusColor: const Color(0xFFFF7A16),
                  address: 'Rua Robert Petter, 89 (Centro)',
                  distance: 'Próxima da rota',
                  distanceColor: const Color(0xFF0D5C34),
                  product: '2 Cestas Econômicas',
                  productColor: const Color(0xFFB9D2BE),
                  amount: 'R\$ 110,00',
                  amountColor: const Color(0xFFC62828),
                ),
                const SizedBox(height: 80), // space for FAB
              ],
            ),
          ),
          // Floating Action Button
          floatingActionButton: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A16),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(255,122,22,0.28),
                  spreadRadius: 0,
                  blurRadius: 24,
                  offset: Offset(0,12),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text('Nova Venda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
  }
}

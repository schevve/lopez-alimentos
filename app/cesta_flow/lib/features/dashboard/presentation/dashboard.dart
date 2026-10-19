import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metrics_row.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/sale_card.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:cesta_flow/features/shared/bottom_bar.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:cesta_flow/features/shared/bottom_bar.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: const TopBar(pagTitle: 'Início'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            MetricsRow(),
            const SizedBox(height: 14),
            // Pills
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     _Pill(
            //       label: 'Vence Hoje',
            //       selected: true,
            //       badgeCount: 7,
            //       badgeColor: const Color(0xFFB9D2BE),
            //     ),
            //     _Pill(
            //       label: 'Atrasados',
            //       badgeCount: 3,
            //       badgeColor: const Color(0xFFC62828),
            //     ),
            //     _Pill(label: 'Agendados'),
            //   ],
            // ),
            Text(
              'Últimas vendas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 14),
            // Client Cards
            SaleCard(
              name: 'José Aparecido dos Santos',
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
            SaleCard(
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
            SaleCard(
              name: 'Ângelo Pereira de Souza',
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
            const SizedBox(height: 100), // space for FAB
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: FilledButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SaleRegistration()),
          );
        },
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.black,
          elevation: 6,
        ),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A16),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(255, 122, 22, 0.28),
                spreadRadius: 0,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_rounded, color: Colors.white, size: 30),
              SizedBox(width: 8),
              Text(
                'Registrar Venda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Pill widget
class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final int? badgeCount;
  final Color? badgeColor;
  _Pill({required this.label})
    : selected = false,
      badgeCount = null,
      badgeColor = null;

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
          Text(
            label,
            style: TextStyle(
              color: txt,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (badgeCount != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

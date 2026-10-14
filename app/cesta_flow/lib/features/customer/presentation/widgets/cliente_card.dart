import 'package:flutter/material.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';

class ClienteCard extends StatelessWidget {
  const ClienteCard({super.key, required this.cliente, required this.onAcao});
  final Customer cliente;
  final ValueChanged<String> onAcao;

  @override
  Widget build(BuildContext context) {
    final local = [
      cliente.address,
      cliente.city,
      cliente.state,
    ].where((parte) => parte.trim().isNotEmpty).join(' • ');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF194D30).withValues(alpha: .025),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NULL significa que o score ainda não foi informado, nunca score zero.
          LayoutBuilder(
            builder: (context, constraints) {
              final nome = Text(
                cliente.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.45,
                  color: Color(0xFF18251F),
                ),
              );
              final badge = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  cliente.score == null
                      ? 'Score não informado'
                      : 'Score: ${cliente.score}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF46524B),
                  ),
                ),
              );
              if (constraints.maxWidth < 380 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [nome, const SizedBox(height: 8), badge],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nome),
                  const SizedBox(width: 12),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'CPF: ${cliente.documentCPF}',
            style: const TextStyle(color: Color(0xFF46524B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF46524B),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  local,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: Color(0xFF46524B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF7F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: Color(0xFF1D5335),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(cliente.phone)),
                TextButton(
                  onPressed: () => onAcao('Ligar'),
                  child: const Text('Ligar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final empilhar =
                  constraints.maxWidth < 330 ||
                  MediaQuery.textScalerOf(context).scale(16) > 21;
              final largura = empilhar
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: largura,
                    child: _AcaoButton(
                      label: 'Ver Perfil',
                      icon: Icons.badge_outlined,
                      background: const Color(0xFFE3F2E9),
                      foreground: const Color(0xFF46524B),
                      onTap: () => onAcao('Ver Perfil'),
                    ),
                  ),
                  SizedBox(
                    width: largura,
                    child: _AcaoButton(
                      label: 'Nova Venda',
                      icon: Icons.add_shopping_cart,
                      background: const Color(0xFFFF7816),
                      foreground: Colors.white,
                      onTap: () => onAcao('Nova Venda'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AcaoButton extends StatelessWidget {
  const _AcaoButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      minimumSize: const Size(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

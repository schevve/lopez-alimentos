import 'package:cesta_flow/features/payment/presentation/payment_registration.dart';
import 'package:cesta_flow/features/sale/presentation/sale_details.dart';
import 'package:flutter/material.dart';

class SaleCard extends StatelessWidget {
  final int? saleId;
  final String name;
  final String? scoreLabel;
  final String status;
  final String address;
  final String? distance;
  final String product;
  final String amount;
  const SaleCard({
    required this.saleId,
    required this.name,
    this.scoreLabel,
    required this.status,
    required this.address,
    this.distance,
    required this.product,
    required this.amount,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              final nome = Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.45,
                  color: Color(0xFF18251F),
                ),
              );
              final badge = scoreLabel == null
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3F1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        scoreLabel!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF46524B),
                        ),
                      ),
                    );
              if (badge == null) return nome;
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
          Text(status, style: const TextStyle(color: Color(0xFF46524B))),
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
                  address,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: Color(0xFF46524B),
                  ),
                ),
              ),
            ],
          ),
          if (distance != null) ...[
            const SizedBox(height: 8),
            Text(
              distance!,
              style: const TextStyle(fontSize: 15, color: Color(0xFF46524B)),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF7F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: Color(0xFF1D5335),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product,
                    style: const TextStyle(color: Color(0xFF18251F)),
                  ),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D5335),
                  ),
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
                      label: 'Ver Venda',
                      icon: Icons.receipt_long_outlined,
                      background: const Color(0xFFE3F2E9),
                      foreground: const Color(0xFF46524B),
                      onTap: saleId == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SaleDetails(saleId: saleId!),
                                ),
                              );
                            },
                    ),
                  ),
                  SizedBox(
                    width: largura,
                    child: _AcaoButton(
                      label: 'Receber',
                      icon: Icons.payments_outlined,
                      background: const Color(0xFFFF7816),
                      foreground: Colors.white,
                      onTap: saleId == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PaymentRegistration(saleId: saleId!),
                                ),
                              );
                            },
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withValues(alpha: .5),
      disabledForegroundColor: foreground.withValues(alpha: .5),
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

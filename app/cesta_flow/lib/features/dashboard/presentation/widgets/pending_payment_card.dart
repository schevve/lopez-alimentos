import 'package:cesta_flow/features/payment/presentation/payment_registration.dart';
import 'package:flutter/material.dart';

class PendingPaymentCard extends StatelessWidget {
  const PendingPaymentCard({
    required this.saleId,
    required this.customerName,
    required this.dueDateLabel,
    required this.amount,
    required this.isOverdue,
    this.onAfterReceive,
    super.key,
  });

  final int? saleId;
  final String customerName;
  final String dueDateLabel;
  final String amount;
  final bool isOverdue;
  final Future<void> Function()? onAfterReceive;

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
                customerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.45,
                  color: Color(0xFF18251F),
                ),
              );
              final badge = isOverdue
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Atrasado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    )
                  : null;
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
          Text(
            'Previsto para $dueDateLabel',
            style: TextStyle(
              color: isOverdue
                  ? const Color(0xFFC62828)
                  : const Color(0xFF46524B),
              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
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
                  Icons.payments_outlined,
                  size: 20,
                  color: Color(0xFF1D5335),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Valor previsto',
                    style: TextStyle(color: Color(0xFF18251F)),
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
          SizedBox(
            width: double.infinity,
            child: _AcaoButton(
              label: 'Receber',
              icon: Icons.payments_outlined,
              background: const Color(0xFFFF7816),
              foreground: Colors.white,
              onTap: saleId == null
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PaymentRegistration(saleId: saleId!),
                        ),
                      );
                      await onAfterReceive?.call();
                    },
            ),
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
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap == null ? null : () => onTap!(),
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
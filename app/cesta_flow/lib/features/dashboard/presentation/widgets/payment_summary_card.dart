import 'package:cesta_flow/features/payment/presentation/payment_registration.dart';
import 'package:flutter/material.dart';

enum PaymentSummaryBadge { onTime, overdue, paid }

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountLabel,
    required this.badge,
    this.saleId,
    this.isPaid = false,
    this.onAfterReceive,
    super.key,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String amountLabel;
  final PaymentSummaryBadge badge;
  final int? saleId;
  final bool isPaid;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.45,
                    color: Color(0xFF18251F),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(kind: badge),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: badge == PaymentSummaryBadge.overdue
                  ? const Color(0xFFC62828)
                  : const Color(0xFF46524B),
              fontWeight: badge == PaymentSummaryBadge.overdue
                  ? FontWeight.w600
                  : FontWeight.normal,
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
                Expanded(
                  child: Text(
                    amountLabel,
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
          SizedBox(
            width: double.infinity,
            child: _ReceiveButton(
              isPaid: isPaid,
              saleId: saleId,
              onAfterReceive: onAfterReceive,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.kind});

  final PaymentSummaryBadge kind;

  @override
  Widget build(BuildContext context) {
    final ({String label, Color background, Color foreground}) style =
        switch (kind) {
          PaymentSummaryBadge.onTime => (
            label: 'Dentro do prazo',
            background: const Color(0xFFEEF7F1),
            foreground: const Color(0xFF1D5335),
          ),
          PaymentSummaryBadge.overdue => (
            label: 'Atrasado',
            background: const Color(0xFFFDECEA),
            foreground: const Color(0xFFC62828),
          ),
          PaymentSummaryBadge.paid => (
            label: 'Pago',
            background: const Color(0xFFEEF7F1),
            foreground: const Color(0xFF1D5335),
          ),
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: style.foreground,
        ),
      ),
    );
  }
}

class _ReceiveButton extends StatelessWidget {
  const _ReceiveButton({
    required this.isPaid,
    required this.saleId,
    this.onAfterReceive,
  });

  final bool isPaid;
  final int? saleId;
  final Future<void> Function()? onAfterReceive;

  @override
  Widget build(BuildContext context) {
    final label = isPaid ? 'Pago' : 'Receber';
    final background =
        isPaid ? const Color(0xFFE8ECE9) : const Color(0xFFFF7816);
    final foreground =
        isPaid ? const Color(0xFF707070) : Colors.white;
    final icon = isPaid ? Icons.check_circle_outline : Icons.payments_outlined;

    return FilledButton(
      onPressed: isPaid || saleId == null
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentRegistration(saleId: saleId!),
                ),
              );
              await onAfterReceive?.call();
            },
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
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
}

PaymentSummaryBadge badgeForUnpaidDueDate(DateTime? dueDate) {
  if (dueDate == null) return PaymentSummaryBadge.onTime;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  if (dueDay.isBefore(today)) {
    return PaymentSummaryBadge.overdue;
  }
  return PaymentSummaryBadge.onTime;
}
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:flutter/material.dart';

class BasketCard extends StatelessWidget {
  const BasketCard({
    super.key,
    required this.basket,
    required this.onEdit,
  });

  final Basket basket;
  final VoidCallback onEdit;

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
          Text(
            basket.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -.45,
              color: Color(0xFF18251F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(basket.price),
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              color: Color(0xFF46524B),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE3F2E9),
                foregroundColor: const Color(0xFF46524B),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined, size: 21),
                  SizedBox(width: 6),
                  Text(
                    'Editar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
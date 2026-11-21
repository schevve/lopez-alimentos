import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/payment_summary_card.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/sale_card.dart';
import 'package:flutter/material.dart';

enum DashboardListTab { payments, sales }

class DashboardListsCarousel extends StatefulWidget {
  const DashboardListsCarousel({
    required this.isLoading,
    this.errorMessage,
    required this.paymentInstallments,
    required this.latestSales,
    required this.customersById,
    required this.saleCustomerIds,
    required this.basketLabels,
    this.onAfterReceive,
    super.key,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<Installment> paymentInstallments;
  final List<Sale> latestSales;
  final Map<int, Customer> customersById;
  final Map<int, int> saleCustomerIds;
  final Map<int, String> basketLabels;
  final Future<void> Function()? onAfterReceive;

  @override
  State<DashboardListsCarousel> createState() => _DashboardListsCarouselState();
}

class _DashboardListsCarouselState extends State<DashboardListsCarousel> {
  DashboardListTab _selectedTab = DashboardListTab.payments;
  bool _enterFromRight = true;

  void _selectTab(DashboardListTab tab) {
    if (_selectedTab == tab) return;
    setState(() {
      _enterFromRight = tab == DashboardListTab.sales;
      _selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ListTabButton(
                label: 'Pagamentos',
                selected: _selectedTab == DashboardListTab.payments,
                onTap: () => _selectTab(DashboardListTab.payments),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ListTabButton(
                label: 'Vendas',
                selected: _selectedTab == DashboardListTab.sales,
                onTap: () => _selectTab(DashboardListTab.sales),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRect(
          clipBehavior: Clip.hardEdge,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final isIncoming = child.key == ValueKey(_selectedTab);
              final Animation<Offset> offsetAnimation;
              if (isIncoming) {
                offsetAnimation =
                    Tween<Offset>(
                      begin: Offset(_enterFromRight ? 1.0 : -1.0, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
              } else {
                // Com ReverseAnimation do AnimatedSwitcher: centro → lado oposto.
                offsetAnimation =
                    Tween<Offset>(
                      begin: Offset(_enterFromRight ? -1.0 : 1.0, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInCubic,
                      ),
                    );
              }
              return SlideTransition(position: offsetAnimation, child: child);
            },
            child: _selectedTab == DashboardListTab.payments
                ? KeyedSubtree(
                    key: const ValueKey(DashboardListTab.payments),
                    child: _buildPaymentsPage(),
                  )
                : KeyedSubtree(
                    key: const ValueKey(DashboardListTab.sales),
                    child: _buildSalesPage(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsPage() {
    if (widget.isLoading) {
      return const _CenteredMessage(child: CircularProgressIndicator());
    }
    if (widget.errorMessage != null) {
      return _CenteredMessage(
        child: Text(
          widget.errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFFC62828)),
        ),
      );
    }
    if (widget.paymentInstallments.isEmpty) {
      return const _CenteredMessage(
        child: Text(
          'Nenhum pagamento registrado.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF707070)),
        ),
      );
    }

    return Column(
      children: [
        for (
          var index = 0;
          index < widget.paymentInstallments.length;
          index++
        ) ...[
          if (index > 0) const SizedBox(height: 14),
          _buildPaymentCard(widget.paymentInstallments[index]),
        ],
      ],
    );
  }

  Widget _buildSalesPage() {
    if (widget.isLoading) {
      return const _CenteredMessage(child: CircularProgressIndicator());
    }
    if (widget.errorMessage != null) {
      return _CenteredMessage(
        child: Text(
          widget.errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFFC62828)),
        ),
      );
    }
    if (widget.latestSales.isEmpty) {
      return const _CenteredMessage(
        child: Text(
          'Nenhuma venda registrada ainda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF707070)),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < widget.latestSales.length; index++) ...[
          if (index > 0) const SizedBox(height: 14),
          _buildSaleCard(widget.latestSales[index]),
        ],
      ],
    );
  }

  Widget _buildPaymentCard(Installment installment) {
    final customerId = widget.saleCustomerIds[installment.saleId];
    final customer = customerId == null
        ? null
        : widget.customersById[customerId];
    final isPaid = installment.isPaid;
    final due = installment.dueDate;
    final dueLabel = due == null ? 'data não definida' : _formatDate(due);
    final paymentDate = installment.paymentDate;
    final indicated = installment.indicatedPaymentDate;
    final subtitle = isPaid
        ? 'Pago em ${paymentDate == null ? '—' : _formatDate(paymentDate)}'
        : indicated == null
        ? 'Vence em $dueLabel'
        : 'Pagamento previsto para ${_formatDate(indicated)} · Vence em $dueLabel';
    final badge = isPaid
        ? PaymentSummaryBadge.paid
        : badgeForUnpaidDueDate(due);

    return PaymentSummaryCard(
      title: customer?.name ?? 'Cliente #${customerId ?? installment.saleId}',
      subtitle: subtitle,
      amount: formatCurrency(
        isPaid ? installment.paidAmount : installment.expectedAmount,
      ),
      amountLabel: isPaid ? 'Valor pago' : 'Valor previsto',
      badge: badge,
      saleId: installment.saleId,
      isPaid: isPaid,
      onAfterReceive: widget.onAfterReceive,
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final customer = widget.customersById[sale.customerId];
    final address = customer == null
        ? 'Endereço não informado'
        : '${customer.address} (${customer.city})';

    return SaleCard(
      saleId: sale.id,
      name: customer?.name ?? 'Cliente #${sale.customerId}',
      status: 'Registrada em ${_formatDate(sale.createdAt)}',
      address: address,
      product: widget.basketLabels[sale.id] ?? 'Cesta',
      amount: formatCurrency(sale.price),
      onAfterReceive: widget.onAfterReceive,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _ListTabButton extends StatelessWidget {
  const _ListTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D5335),
        side: BorderSide(
          color: const Color(0xFF1D5335),
          width: selected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.greenText,
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: child),
    );
  }
}

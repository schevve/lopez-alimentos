import 'dart:math' as math;

import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/domain/score_band.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/customer/presentation/customer_edit.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metrics_row.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class CustomerDetails extends StatefulWidget {
  const CustomerDetails({
    super.key,
    required this.customerId,
    this.customerRepository,
    this.saleRepository,
    this.installmentRepository,
  });

  final int customerId;
  final CustomerRepository? customerRepository;
  final SaleRepository? saleRepository;
  final InstallmentRepository? installmentRepository;

  @override
  State<CustomerDetails> createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {
  late final CustomerRepository _customerRepository =
      widget.customerRepository ?? CustomerRepository();
  late final SaleRepository _saleRepository =
      widget.saleRepository ?? SaleRepository();
  late final InstallmentRepository _installmentRepository =
      widget.installmentRepository ?? InstallmentRepository();
  late Future<_CustomerDetailsData> _details;

  @override
  void initState() {
    super.initState();
    _details = _loadDetails();
  }

  Future<_CustomerDetailsData> _loadDetails() async {
    final customer = await _customerRepository.getCustomerById(
      widget.customerId,
    );
    if (customer == null) {
      return const _CustomerDetailsData(customer: null);
    }

    final sales = await _saleRepository.getSalesByCustomerId(widget.customerId);
    final saleIds = sales.map((sale) => sale.id).whereType<int>().toList();
    final paymentTotals = await _installmentRepository.paidTotalsBySaleIds(
      saleIds,
    );
    final basketLabels = await _saleRepository.basketLabelsFor(saleIds);

    return _CustomerDetailsData(
      customer: customer,
      sales: sales,
      paymentTotals: paymentTotals,
      basketLabels: basketLabels,
    );
  }

  void _reload() {
    setState(() {
      _details = _loadDetails();
    });
  }

  Future<void> _refresh() async {
    final details = _loadDetails();
    setState(() {
      _details = details;
    });
    await details;
  }

  Future<void> _editCustomer(Customer customer) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CustomerEdit(customer: customer, repository: _customerRepository),
      ),
    );
    if (updated == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0FDF4),
    appBar: const TopBar(pagTitle: 'Detalhes do cliente'),
    body: FutureBuilder<_CustomerDetailsData>(
      future: _details,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            message: 'Não foi possível carregar os dados do cliente.',
            actionLabel: 'Tentar novamente',
            onAction: _reload,
          );
        }

        final data = snapshot.data!;
        final customer = data.customer;
        if (customer == null) {
          return const _MessageState(message: 'Cliente não encontrado.');
        }

        final summaries = data.sales
            .map(
              (sale) => _SaleSummary(
                sale: sale,
                label: data.basketLabels[sale.id] ?? 'Cesta',
                total: sale.price,
                paid: math.max(
                  0,
                  data.paymentTotals[sale.id] ?? sale.amountPaid,
                ).toDouble(),
              ),
            )
            .toList();
        final totalSales = summaries.fold<double>(
          0,
          (total, summary) => total + summary.total,
        );
        final totalPaid = summaries.fold<double>(
          0,
          (total, summary) => total + summary.paid,
        );
        final pending = summaries
            .where((summary) => summary.balance > 0)
            .toList();
        final totalPending = pending.fold<double>(
          0,
          (total, summary) => total + summary.balance,
        );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _customerCard(customer),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Resumo financeiro'),
              const SizedBox(height: 12),
              MetricsRow(
                columns: 2,
                cards: [
                  MetricCard(
                    title: 'Total de compras',
                    value: formatCurrency(totalSales),
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppColors.primary,
                  ),
                  MetricCard(
                    title: 'Total pago',
                    value: formatCurrency(totalPaid),
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.primary,
                  ),
                  MetricCard(
                    title: 'Saldo em aberto',
                    value: formatCurrency(totalPending),
                    icon: Icons.pending_actions_outlined,
                    iconColor: AppColors.primary,
                    alert: totalPending > 0,
                  ),
                  MetricCard(
                    title: 'Vendas registradas',
                    value: '${data.sales.length}',
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Vendas com saldo pendente'),
              const SizedBox(height: 6),
              const Text(
                'O sistema registra pagamentos por venda, mas não possui '
                'parcelas ou datas de vencimento.',
                style: TextStyle(color: Color(0xFF59665E), height: 1.4),
              ),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                const _EmptySection(
                  message: 'Este cliente não possui vendas em aberto.',
                )
              else
                for (final summary in pending)
                  _SaleCard(summary: summary),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Histórico de vendas (${data.sales.length})'),
              const SizedBox(height: 12),
              if (summaries.isEmpty)
                const _EmptySection(
                  message: 'Este cliente ainda não possui vendas.',
                )
              else
                for (final summary in summaries)
                  _SaleCard(summary: summary),
            ],
          ),
        );
      },
    ),
  );

  Widget _customerCard(Customer customer) {
    final address = [
      customer.address,
      customer.city,
      customer.state,
      if (customer.cep?.isNotEmpty ?? false) 'CEP ${customer.cep}',
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2E9),
                  foregroundColor: Color(0xFF1B4D31),
                  child: Icon(Icons.person_outline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18251F),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar cliente',
                  onPressed: () => _editCustomer(customer),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoLine(label: 'CPF', value: customer.documentCPF),
            _InfoLine(label: 'Telefone', value: customer.phone),
            if (customer.email?.isNotEmpty ?? false)
              _InfoLine(label: 'E-mail', value: customer.email!),
            _InfoLine(
              label: 'Endereço',
              value: address.isEmpty ? 'Não informado' : address,
            ),
            _InfoLine(
              label: 'Data de nascimento',
              value: customer.dateOfBirth == null
                  ? 'Não informada'
                  : _formatDate(customer.dateOfBirth!),
            ),
            _InfoLine(
              label: 'Score',
              value: customer.score == null
                  ? 'Não informado'
                  : '${_formatScore(customer.score!)} · ${ScoreBand.fromScore(customer.score)!.label}',
            ),
            if (customer.isBlocked)
              const _InfoLine(label: 'Situação', value: 'Bloqueado'),
            if (customer.id != null)
              _InfoLine(label: 'Código do cliente', value: '#${customer.id}'),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatScore(double score) => score == score.roundToDouble()
    ? score.toInt().toString()
    : score.toString();

class _CustomerDetailsData {
  const _CustomerDetailsData({
    required this.customer,
    this.sales = const [],
    this.paymentTotals = const {},
    this.basketLabels = const {},
  });

  final Customer? customer;
  final List<Sale> sales;
  final Map<int, double> paymentTotals;
  final Map<int, String> basketLabels;
}

class _SaleSummary {
  const _SaleSummary({
    required this.sale,
    required this.label,
    required this.total,
    required this.paid,
  });

  final Sale sale;
  final String label;
  final double total;
  final double paid;

  double get balance => math.max(0, total - paid).toDouble();
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.summary});

  final _SaleSummary summary;

  @override
  Widget build(BuildContext context) {
    final sale = summary.sale;
    final isOpen = summary.balance > 0;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Venda #${sale.id ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  isOpen
                      ? summary.paid > 0
                            ? 'Parcialmente paga'
                            : 'Em aberto'
                      : 'Paga',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isOpen
                        ? const Color(0xFFB54708)
                        : const Color(0xFF1B4D31),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.label} • ${_formatDate(sale.createdAt)}',
              style: const TextStyle(color: Color(0xFF59665E)),
            ),
            const SizedBox(height: 10),
            _InfoLine(label: 'Valor da venda', value: formatCurrency(summary.total)),
            _InfoLine(label: 'Total pago', value: formatCurrency(summary.paid)),
            _InfoLine(
              label: 'Saldo restante',
              value: formatCurrency(summary.balance),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF59665E)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF18251F),
    ),
  );
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/payment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class SaleDetails extends StatefulWidget {
  const SaleDetails({
    super.key,
    required this.saleId,
    this.saleRepository,
    this.paymentRepository,
    this.customerRepository,
  });

  final int saleId;
  final SaleRepository? saleRepository;
  final PaymentRepository? paymentRepository;
  final CustomerRepository? customerRepository;

  @override
  State<SaleDetails> createState() => _SaleDetailsState();
}

class _SaleDetailsState extends State<SaleDetails> {
  late final SaleRepository _saleRepository =
      widget.saleRepository ?? SaleRepository();
  late final PaymentRepository _paymentRepository =
      widget.paymentRepository ?? PaymentRepository();
  late final CustomerRepository _customerRepository =
      widget.customerRepository ?? CustomerRepository();
  late Future<_SaleDetailsData> _details;

  @override
  void initState() {
    super.initState();
    _details = _loadDetails();
  }

  Future<_SaleDetailsData> _loadDetails() async {
    final sale = await _saleRepository.getSaleById(widget.saleId);
    if (sale == null) {
      return const _SaleDetailsData(sale: null);
    }

    final paid = await _paymentRepository.getPaymentsBySaleIdAmount(
      widget.saleId,
    );
    final customer = await _customerRepository.getCustomerById(sale.customerId);

    return _SaleDetailsData(sale: sale, paid: paid, customer: customer);
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0FDF4),
    appBar: const TopBar(pagTitle: 'Detalhes da venda'),
    body: FutureBuilder<_SaleDetailsData>(
      future: _details,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            message: 'Não foi possível carregar os dados da venda.',
            actionLabel: 'Tentar novamente',
            onAction: _reload,
          );
        }

        final data = snapshot.data!;
        final sale = data.sale;
        if (sale == null) {
          return const _MessageState(message: 'Venda não encontrada.');
        }

        final saleValue = sale.price * sale.quantity;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _saleHeader(sale, data.customer),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Resumo da venda'),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(
                        width: cardWidth,
                        title: 'Valor da venda',
                        value: formatCurrency(saleValue),
                        icon: Icons.shopping_bag_outlined,
                      ),
                      _MetricCard(
                        width: cardWidth,
                        title: 'Valor pago',
                        value: formatCurrency(data.paid),
                        icon: Icons.payments_outlined,
                      ),
                      _MetricCard(
                        width: cardWidth,
                        title: 'Parcelas',
                        value: '${_mockInstallments.length}',
                        icon: Icons.calendar_month_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Produtos'),
              const SizedBox(height: 12),
              _ProductCard(sale: sale),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Parcelas'),
              const SizedBox(height: 6),
              const Text(
                'Valores ilustrativos. O modelo de parcelas ainda não está pronto.',
                style: TextStyle(color: Color(0xFF59665E), height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final installment in _mockInstallments)
                _InstallmentCard(installment: installment),
            ],
          ),
        );
      },
    ),
  );

  Widget _saleHeader(Sale sale, Customer? customer) {
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
                  child: Icon(Icons.receipt_long_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Venda #${sale.id ?? widget.saleId}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18251F),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoLine(
              label: 'Cliente',
              value: customer?.name ?? 'Cliente #${sale.customerId}',
            ),
            _InfoLine(label: 'Data', value: _formatDate(sale.date)),
            if (sale.description.trim().isNotEmpty)
              _InfoLine(label: 'Observações', value: sale.description),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

const _mockInstallments = [
  _MockInstallment(number: 1, amount: 50, status: 'Paga'),
  _MockInstallment(number: 2, amount: 50, status: 'Pendente'),
];

class _SaleDetailsData {
  const _SaleDetailsData({required this.sale, this.paid = 0, this.customer});

  final Sale? sale;
  final double paid;
  final Customer? customer;
}

class _MockInstallment {
  const _MockInstallment({
    required this.number,
    required this.amount,
    required this.status,
  });

  final int number;
  final double amount;
  final String status;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1B4D31)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Color(0xFF59665E))),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18251F),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final total = sale.price * sale.quantity;
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sale.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _InfoLine(label: 'Quantidade', value: '${sale.quantity}'),
            _InfoLine(
              label: 'Valor unitário',
              value: formatCurrency(sale.price),
            ),
            _InfoLine(label: 'Total', value: formatCurrency(total)),
          ],
        ),
      ),
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({required this.installment});

  final _MockInstallment installment;

  @override
  Widget build(BuildContext context) {
    final isPaid = installment.status == 'Paga';
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
                    'Parcela ${installment.number}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  installment.status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPaid
                        ? const Color(0xFF1B4D31)
                        : const Color(0xFFB54708),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoLine(
              label: 'Valor',
              value: formatCurrency(installment.amount),
            ),
          ],
        ),
      ),
    );
  }
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

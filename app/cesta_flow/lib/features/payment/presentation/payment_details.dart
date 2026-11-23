import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/payment_summary_card.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class PaymentDetails extends StatefulWidget {
  const PaymentDetails({
    super.key,
    required this.installmentId,
    this.installmentRepository,
    this.saleRepository,
    this.customerRepository,
  });

  final int installmentId;
  final InstallmentRepository? installmentRepository;
  final SaleRepository? saleRepository;
  final CustomerRepository? customerRepository;

  @override
  State<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  late final InstallmentRepository _installmentRepository =
      widget.installmentRepository ?? InstallmentRepository();
  late final SaleRepository _saleRepository =
      widget.saleRepository ?? SaleRepository();
  late final CustomerRepository _customerRepository =
      widget.customerRepository ?? CustomerRepository();
  late Future<_PaymentDetailsData> _details;

  @override
  void initState() {
    super.initState();
    _details = _loadDetails();
  }

  Future<_PaymentDetailsData> _loadDetails() async {
    final installment = await _installmentRepository.getInstallmentById(
      widget.installmentId,
    );
    if (installment == null) {
      return const _PaymentDetailsData(installment: null);
    }

    final sale = await _saleRepository.getSaleById(installment.saleId);
    final installments = await _installmentRepository.getInstallmentsBySaleId(
      installment.saleId,
    );
    final installmentNumber = _installmentIndex(installments, installment) + 1;
    final customer = sale == null
        ? null
        : await _customerRepository.getCustomerById(sale.customerId);

    return _PaymentDetailsData(
      installment: installment,
      sale: sale,
      customer: customer,
      installmentNumber: installmentNumber,
      installmentsCount: installments.length,
    );
  }

  int _installmentIndex(List<Installment> installments, Installment current) {
    final id = current.id;
    if (id != null) {
      final byId = installments.indexWhere((item) => item.id == id);
      if (byId >= 0) return byId;
    }
    return installments.indexWhere((item) => item.uuid == current.uuid);
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
    appBar: const TopBar(pagTitle: 'Detalhes do pagamento'),
    body: FutureBuilder<_PaymentDetailsData>(
      future: _details,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            message: 'Não foi possível carregar os dados do pagamento.',
            actionLabel: 'Tentar novamente',
            onAction: _reload,
          );
        }

        final data = snapshot.data!;
        final installment = data.installment;
        if (installment == null) {
          return const _MessageState(message: 'Pagamento não encontrado.');
        }

        final isPaid = installment.isPaid;
        final badge = isPaid
            ? PaymentSummaryBadge.paid
            : badgeForUnpaidDueDate(installment.dueDate);
        final statusLabel = _statusLabel(badge);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _paymentHeader(data),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Resumo do pagamento'),
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
                        title: 'Valor previsto',
                        value: formatCurrency(installment.expectedAmount),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _MetricCard(
                        width: cardWidth,
                        title: 'Valor pago',
                        value: formatCurrency(
                          isPaid ? installment.paidAmount : 0,
                        ),
                        icon: Icons.payments_outlined,
                      ),
                      _MetricCard(
                        width: cardWidth,
                        title: 'Situação',
                        value: statusLabel,
                        icon: Icons.flag_outlined,
                      ),
                      if (data.sale != null)
                        _MetricCard(
                          width: cardWidth,
                          title: 'Venda',
                          value: 'Venda #${data.sale!.id ?? installment.saleId}',
                          icon: Icons.receipt_long_outlined,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Datas e forma de pagamento'),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoLine(
                        label: 'Vencimento',
                        value: installment.dueDate == null
                            ? 'Não definido'
                            : _formatDate(installment.dueDate!),
                      ),
                      _InfoLine(
                        label: 'Data do pagamento',
                        value: installment.paymentDate == null
                            ? 'Não pago'
                            : _formatDate(installment.paymentDate!),
                      ),
                      if (installment.indicatedPaymentDate != null)
                        _InfoLine(
                          label: 'Visita indicada',
                          value: _formatDate(installment.indicatedPaymentDate!),
                        ),
                      _InfoLine(
                        label: 'Forma de pagamento',
                        value: installment.paymentMethod ?? '—',
                      ),
                      _InfoLine(
                        label: 'Registrado em',
                        value: _formatDate(installment.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isPaid) ...[
                const SizedBox(height: 24),
                PaymentSummaryCard(
                  title: 'Receber pagamento',
                  subtitle: _unpaidSubtitle(installment),
                  amount: formatCurrency(installment.expectedAmount),
                  amountLabel: 'Valor previsto',
                  badge: badge,
                  saleId: installment.saleId,
                  isPaid: false,
                  onAfterReceive: _refresh,
                ),
              ],
            ],
          ),
        );
      },
    ),
  );

  Widget _paymentHeader(_PaymentDetailsData data) {
    final installment = data.installment!;
    final displayId = installment.id ?? widget.installmentId;
    final parcelLabel = data.installmentsCount > 0
      ? 'Parcela ${data.installmentNumber} de ${data.installmentsCount}'
      : 'Parcela ${data.installmentNumber}';

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
                  child: Icon(Icons.payments_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pagamento #$displayId',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18251F),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar pagamento',
                  onPressed: null,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoLine(
              label: 'Cliente',
              value:
                  data.customer?.name ??
                  (data.sale == null
                      ? '—'
                      : 'Cliente #${data.sale!.customerId}'),
            ),
            if (data.sale != null)
              _InfoLine(
                label: 'Venda',
                value: 'Venda #${data.sale!.id ?? installment.saleId}',
              ),
            _InfoLine(label: 'Parcela', value: parcelLabel),
          ],
        ),
      ),
    );
  }

  String _unpaidSubtitle(Installment installment) {
    final due = installment.dueDate;
    final dueLabel = due == null ? 'data não definida' : _formatDate(due);
    final indicated = installment.indicatedPaymentDate;
    if (indicated == null) {
      return 'Previsto para $dueLabel';
    }
    return 'Previsto para $dueLabel · Visita indicada em ${_formatDate(indicated)}';
  }

  String _statusLabel(PaymentSummaryBadge badge) {
    return switch (badge) {
      PaymentSummaryBadge.paid => 'Pago',
      PaymentSummaryBadge.overdue => 'Atrasado',
      PaymentSummaryBadge.onTime => 'Dentro do prazo',
    };
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _PaymentDetailsData {
  const _PaymentDetailsData({
    required this.installment,
    this.sale,
    this.customer,
    this.installmentNumber = 1,
    this.installmentsCount = 0,
  });

  final Installment? installment;
  final Sale? sale;
  final Customer? customer;
  final int installmentNumber;
  final int installmentsCount;
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
          child: Text(label, style: const TextStyle(color: Color(0xFF59665E))),
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
  const _MessageState({required this.message, this.actionLabel, this.onAction});

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
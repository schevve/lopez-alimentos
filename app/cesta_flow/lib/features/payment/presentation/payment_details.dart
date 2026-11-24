import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metrics_row.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/payment_summary_card.dart';
import 'package:cesta_flow/features/payment/presentation/payment_edit.dart';
import 'package:cesta_flow/features/payment/presentation/payment_registration.dart';
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
  Widget build(BuildContext context) => FutureBuilder<_PaymentDetailsData>(
    future: _details,
    builder: (context, snapshot) {
      Widget body;
      int? openPaymentSaleId;

      if (snapshot.connectionState != ConnectionState.done) {
        body = const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        body = _MessageState(
          message: 'Não foi possível carregar os dados do pagamento.',
          actionLabel: 'Tentar novamente',
          onAction: _reload,
        );
      } else {
        final data = snapshot.data!;
        final installment = data.installment;
        if (installment == null) {
          body = const _MessageState(message: 'Pagamento não encontrado.');
        } else {
          final isPaid = installment.isPaid;
          if (!isPaid) {
            openPaymentSaleId = installment.saleId;
          }
          final badge = isPaid
              ? PaymentSummaryBadge.paid
              : badgeForUnpaidDueDate(installment.dueDate);
          final statusLabel = _statusLabel(badge);

          final canEditPayment = !isPaid;
          body = RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                openPaymentSaleId != null ? 100 : 32,
              ),
              children: [
              _paymentHeader(data, canEditPayment: canEditPayment),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Resumo do pagamento'),
              const SizedBox(height: 12),
              MetricsPanel(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Valor previsto',
                            value: formatCurrency(installment.expectedAmount),
                            subtitle: '',
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Valor pago',
                            value: formatCurrency(
                              isPaid ? installment.paidAmount : 0,
                            ),
                            subtitle: '',
                            icon: Icons.payments_outlined,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Situação',
                            value: statusLabel,
                            subtitle: '',
                            icon: Icons.flag_outlined,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        if (data.sale != null)
                          SizedBox(
                            width: cardWidth,
                            child: MetricCard(
                              title: 'Venda',
                              value:
                                  'Venda #${data.sale!.id ?? installment.saleId}',
                              subtitle: '',
                              icon: Icons.receipt_long_outlined,
                              iconColor: AppColors.primary,
                            ),
                          ),
                      ],
                    );
                  },
                ),
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
              ],
            ),
          );
        }
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        appBar: const TopBar(pagTitle: 'Detalhes do pagamento'),
        body: body,
        floatingActionButton: openPaymentSaleId == null
            ? null
            : FilledButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PaymentRegistration(saleId: openPaymentSaleId!),
                    ),
                  );
                  await _refresh();
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined, color: Colors.white, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Receber pagamento',
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
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      );
    },
  );

  Future<void> _editPayment() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentEdit(installmentId: widget.installmentId),
      ),
    );
    if (updated == true) {
      await _refresh();
    }
  }

  Widget _paymentHeader(
    _PaymentDetailsData data, {
    required bool canEditPayment,
  }) {
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
            Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    backgroundColor: Color(0xFFE3F2E9),
                    foregroundColor: Color(0xFF1B4D31),
                    child: Icon(Icons.payments_outlined),
                  ),
                ),
                Text(
                  'Pagamento #$displayId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18251F),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Editar pagamento',
                    onPressed: canEditPayment ? _editPayment : null,
                    icon: const Icon(Icons.edit_outlined),
                  ),
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
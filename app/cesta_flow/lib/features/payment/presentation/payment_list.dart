import 'package:cesta_flow/core/app_data_refresh.dart';
import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/core/data/remote/sync_on_user_refresh.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/payment_summary_card.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class PaymentList extends StatefulWidget {
  const PaymentList({super.key});

  @override
  State<PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<PaymentList> with AppDataRefreshListener {
  static const _verde = Color(0xFF1B4D31);

  final InstallmentRepository _installmentRepository = InstallmentRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final SaleRepository _saleRepository = SaleRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Installment> _installments = const [];
  Map<int, Customer> _customersById = const {};
  Map<int, int> _saleCustomerIds = const {};

  @override
  void initState() {
    super.initState();
    registerAppDataRefreshListener();
    _loadPaymentsList();
  }

  @override
  void dispose() {
    unregisterAppDataRefreshListener();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void onAppDataChanged() {
    _loadPaymentsList();
  }

  Future<void> _loadPaymentsList({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final installments =
          await _installmentRepository.getInstallmentsForDashboard();
      final customers = await _customerRepository.getAllCustomers();
      final sales = await _saleRepository.getAllSales();

      if (!mounted) return;

      setState(() {
        _installments = installments;
        _customersById = {
          for (final customer in customers)
            if (customer.id != null) customer.id!: customer,
        };
        _saleCustomerIds = {
          for (final sale in sales)
            if (sale.id != null) sale.id!: sale.customerId,
        };
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Erro ao carregar lista de pagamentos: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar os pagamentos.';
      });
    }
  }

  String _normalize(String text) {
    var result = text.toLowerCase();
    const groups = {
      '[áàâãä]': 'a',
      '[éèêë]': 'e',
      '[íìîï]': 'i',
      '[óòôõö]': 'o',
      '[úùûü]': 'u',
      'ç': 'c',
    };
    groups.forEach(
      (pattern, value) => result = result.replaceAll(RegExp(pattern), value),
    );
    return result;
  }

  List<Installment> get _filteredInstallments {
    final query = _normalize(_searchController.text.trim());
    if (query.isEmpty) {
      return _installments;
    }

    final cpfQuery = query.replaceAll(RegExp(r'[^0-9]'), '');

    return _installments.where((installment) {
      final customerId = _saleCustomerIds[installment.saleId];
      final customer =
          customerId == null ? null : _customersById[customerId];
      if (customer == null) {
        return false;
      }

      final matchesName = _normalize(customer.name).contains(query);
      final matchesCpf =
          cpfQuery.isNotEmpty &&
          customer.documentCPF
              .replaceAll(RegExp(r'[^0-9]'), '')
              .contains(cpfQuery);

      return matchesName || matchesCpf;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredInstallments;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: const TopBar(pagTitle: 'Pagamentos', showDrawer: true),
      body: RefreshIndicator(
        onRefresh: () => refreshWithRemoteSync(
          _loadPaymentsList,
          onSyncFailed: (message) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Text(
                'Lista de pagamentos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 16, 0, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _verde,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, CPF...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF808A84),
                      fontSize: 18,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 20,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: _verde,
                      size: 26,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ..._buildPaymentsSection(filtered),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPaymentsSection(List<Installment> installments) {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFFC62828)),
          ),
        ),
      ];
    }

    if (installments.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            _searchController.text.trim().isEmpty
                ? 'Nenhum pagamento registrado.'
                : 'Nenhum pagamento encontrado para a busca.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF707070)),
          ),
        ),
      ];
    }

    return [
      for (var index = 0; index < installments.length; index++) ...[
        if (index > 0) const SizedBox(height: 14),
        _buildPaymentCard(installments[index]),
      ],
    ];
  }

  Widget _buildPaymentCard(Installment installment) {
    final customerId = _saleCustomerIds[installment.saleId];
    final customer =
        customerId == null ? null : _customersById[customerId];
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
      onAfterReceive: () => _loadPaymentsList(showLoadingIndicator: true),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
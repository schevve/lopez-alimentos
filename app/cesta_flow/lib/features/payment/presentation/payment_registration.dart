import 'package:cesta_flow/core/app_data_refresh.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/shared/payment_form.dart';
import 'package:cesta_flow/features/shared/registration_success_screen.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class PaymentRegistration extends StatefulWidget {
  final int saleId;

  const PaymentRegistration({super.key, required this.saleId});

  @override
  State<PaymentRegistration> createState() => _PaymentRegistration();
}

class _PaymentRegistration extends State<PaymentRegistration> {
  final _saleRepository = SaleRepository();
  final _installmentRepository = InstallmentRepository();
  final _customerRepository = CustomerRepository();

  Sale? _sale;
  Customer? _customer;
  double _nextInstallmentAmount = 0;
  double _remainingBalance = 0;
  bool _loading = true;
  String? _loadError;
  int _unpaidInstallmentsCount = 0;

  bool get _showNextVisitField => _unpaidInstallmentsCount > 1;

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final sale = await _saleRepository.getSaleById(widget.saleId);
      if (sale == null) {
        if (!mounted) return;
        setState(() {
          _sale = null;
          _loading = false;
        });
        return;
      }
      final customer = await _customerRepository.getCustomerById(
        sale.customerId,
      );
      final installments = await _installmentRepository.getInstallmentsBySaleId(
        widget.saleId,
      );
      final remaining = SaleRepository.remainingBalance(sale);
      final nextInstallment = _nextInstallmentAmountFor(sale, installments);
      final unpaidCount =
          installments.where((item) => !item.isPaid).length;
      if (!mounted) return;
      setState(() {
        _sale = sale;
        _customer = customer;
        _remainingBalance = remaining;
        _nextInstallmentAmount = nextInstallment;
        _unpaidInstallmentsCount = unpaidCount;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Não foi possível carregar a venda: $error';
        _loading = false;
      });
    }
  }

  double _nextInstallmentAmountFor(Sale sale, List<Installment> installments) {
    final remaining = SaleRepository.remainingBalance(sale);
    if (remaining <= 0) return 0;
    final pending = installments.where((item) => !item.isPaid).toList()
      ..sort((a, b) {
        final dueA = a.dueDate;
        final dueB = b.dueDate;
        if (dueA == null && dueB == null) {
          return a.createdAt.compareTo(b.createdAt);
        }
        if (dueA == null) return 1;
        if (dueB == null) return -1;
        return dueA.compareTo(dueB);
      });
    if (pending.isEmpty) return remaining;
    final expected = pending.first.expectedAmount;
    if (expected <= 0 || expected > remaining) return remaining;
    return expected;
  }

  Future<void> _handleSubmit(PaymentSubmitData data) async {
    try {
      await _installmentRepository.registerPayment(
        saleId: widget.saleId,
        amount: data.amount,
        paymentMethod: data.paymentMethod,
      );
      if (data.nextVisitDate != null) {
        await _installmentRepository.indicateNextPaymentDate(
          saleId: widget.saleId,
          indicatedDate: data.nextVisitDate!,
        );
      }
      if (!mounted) return;
      notifyAppDataChanged();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RegistrationSuccessScreen(
            message: 'Pagamento registrado!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível registrar o pagamento: $error'),
        ),
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3FCF3),
      appBar: const TopBar(pagTitle: 'Registrar pagamento'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return PaymentFormMessageState(
        message: _loadError!,
        actionLabel: 'Tentar novamente',
        onAction: _loadSale,
      );
    }
    final sale = _sale;
    if (sale == null) {
      return const PaymentFormMessageState(message: 'Venda não encontrada.');
    }
    if (SaleRepository.isSaleFullyPaid(sale) || _remainingBalance <= 0) {
      return const PaymentFormMessageState(
        message: 'Esta venda já está quitada.',
      );
    }

    return PaymentForm(
      sale: sale,
      customer: _customer,
      buttonText: 'Registrar pagamento',
      submitLoadingMessage: 'Registrando pagamento...',
      suggestedAmount: _nextInstallmentAmount,
      remainingBalance: _remainingBalance,
      showNextVisitField: _showNextVisitField,
      initialAmountText: formatMoneyField(_nextInstallmentAmount),
      onSubmit: _handleSubmit,
    );
  }
}
import 'package:cesta_flow/core/app_data_refresh.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/shared/payment_form.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class PaymentEdit extends StatefulWidget {
  const PaymentEdit({
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
  State<PaymentEdit> createState() => _PaymentEditState();
}

class _PaymentEditState extends State<PaymentEdit> {
  late final InstallmentRepository _installmentRepository =
      widget.installmentRepository ?? InstallmentRepository();
  late final SaleRepository _saleRepository =
      widget.saleRepository ?? SaleRepository();
  late final CustomerRepository _customerRepository =
      widget.customerRepository ?? CustomerRepository();

  Installment? _installment;
  Sale? _sale;
  Customer? _customer;
  double _suggestedAmount = 0;
  double _remainingBalance = 0;
  bool _showNextVisitField = false;
  String? _initialNextVisit;
  bool _loading = true;
  String? _loadError;
  bool _isPaidInstallment = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _isPaidInstallment = false;
    });
    try {
      final installment = await _installmentRepository.getInstallmentById(
        widget.installmentId,
      );
      if (installment == null) {
        if (!mounted) return;
        setState(() {
          _installment = null;
          _loading = false;
        });
        return;
      }
      if (installment.isPaid) {
        if (!mounted) return;
        setState(() {
          _installment = installment;
          _isPaidInstallment = true;
          _loading = false;
        });
        return;
      }

      final sale = await _saleRepository.getSaleById(installment.saleId);
      if (sale == null) {
        if (!mounted) return;
        setState(() {
          _installment = installment;
          _sale = null;
          _loading = false;
        });
        return;
      }

      final customer = await _customerRepository.getCustomerById(
        sale.customerId,
      );
      final installments = await _installmentRepository.getInstallmentsBySaleId(
        installment.saleId,
      );
      final unpaidCount = installments.where((item) => !item.isPaid).length;
      final remaining = SaleRepository.remainingBalance(sale);
      String? nextVisit;
      if (_showNextVisitForCount(unpaidCount)) {
        final indicated = _nextUnpaidIndicatedDate(installments);
        if (indicated != null) {
          nextVisit = _formatDate(indicated);
        }
      }

      if (!mounted) return;
      setState(() {
        _installment = installment;
        _sale = sale;
        _customer = customer;
        _suggestedAmount = installment.expectedAmount;
        _remainingBalance = remaining;
        _showNextVisitField = _showNextVisitForCount(unpaidCount);
        _initialNextVisit = nextVisit;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Não foi possível carregar o pagamento: $error';
        _loading = false;
      });
    }
  }

  bool _showNextVisitForCount(int unpaidCount) => unpaidCount > 1;

  DateTime? _nextUnpaidIndicatedDate(List<Installment> installments) {
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
    if (pending.isEmpty) return null;
    return pending.first.indicatedPaymentDate;
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _handleSubmit(PaymentSubmitData data) async {
    final installment = _installment;
    final sale = _sale;
    if (installment == null || sale == null) return;

    if (data.amount > SaleRepository.remainingBalance(sale)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O valor previsto não pode exceder o saldo restante da venda.',
          ),
        ),
      );
      return;
    }

    try {
      await _installmentRepository.updateInstallment(
        installment.copyWith(
          expectedAmount: data.amount,
          dueDate: data.dueDate,
          indicatedPaymentDate: data.suggestedPaymentDate,
        ),
      );
      if (data.nextVisitDate != null) {
        await _installmentRepository.indicateNextPaymentDate(
          saleId: installment.saleId,
          indicatedDate: data.nextVisitDate!,
        );
      }
      if (!mounted) return;
      notifyAppDataChanged();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar o pagamento: $error'),
        ),
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3FCF3),
      appBar: const TopBar(pagTitle: 'Editar pagamento'),
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
        onAction: _load,
      );
    }
    final installment = _installment;
    if (installment == null) {
      return const PaymentFormMessageState(message: 'Pagamento não encontrado.');
    }
    if (_isPaidInstallment) {
      return const PaymentFormMessageState(
        message: 'Pagamentos já registrados não podem ser alterados.',
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
      buttonText: 'Salvar alterações',
      submitLoadingMessage: 'Salvando pagamento...',
      suggestedAmount: _suggestedAmount,
      remainingBalance: _remainingBalance,
      showNextVisitField: _showNextVisitField,
      showPaymentMethod: false,
      amountSectionTitle: 'Valor previsto (R\$)',
      amountFieldLabel: 'Valor previsto *',
      initialAmountText: formatMoneyField(installment.expectedAmount),
      initialDueDateText: installment.dueDate == null
          ? null
          : _formatDate(installment.dueDate!),
      initialSuggestedPaymentDateText: installment.indicatedPaymentDate == null
          ? null
          : _formatDate(installment.indicatedPaymentDate!),
      initialNextVisitText: _initialNextVisit,
      onSubmit: _handleSubmit,
    );
  }
}
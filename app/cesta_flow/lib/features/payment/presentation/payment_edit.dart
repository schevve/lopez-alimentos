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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
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
      if (!installment.isPaid) {
        if (!mounted) return;
        setState(() {
          _installment = installment;
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
      final maxForThisPayment =
          sale.price - sale.amountPaid + installment.paidAmount;
      String? nextVisit;
      if (unpaidCount > 0) {
        final nextUnpaid = installments
            .where((item) => !item.isPaid)
            .toList()
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
        final indicated = nextUnpaid.first.indicatedPaymentDate;
        if (indicated != null) {
          nextVisit = _formatDate(indicated);
        }
      }

      if (!mounted) return;
      setState(() {
        _installment = installment;
        _sale = sale;
        _customer = customer;
        _suggestedAmount = installment.paidAmount;
        _remainingBalance = maxForThisPayment;
        _showNextVisitField = unpaidCount > 1;
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _handleSubmit(PaymentSubmitData data) async {
    final installment = _installment;
    final sale = _sale;
    if (installment == null || sale == null) return;

    try {
      await _installmentRepository.updateRegisteredPayment(
        installmentId: widget.installmentId,
        paidAmount: data.amount,
        paymentMethod: data.paymentMethod,
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
    if (!installment.isPaid) {
      return const PaymentFormMessageState(
        message: 'Este pagamento ainda não foi registrado.',
      );
    }
    final sale = _sale;
    if (sale == null) {
      return const PaymentFormMessageState(message: 'Venda não encontrada.');
    }

    return PaymentForm(
      sale: sale,
      customer: _customer,
      buttonText: 'Salvar alterações',
      submitLoadingMessage: 'Salvando pagamento...',
      suggestedAmount: _suggestedAmount,
      remainingBalance: _remainingBalance,
      showNextVisitField: _showNextVisitField,
      initialPaymentMethod: installment.paymentMethod,
      initialAmountText: formatMoneyField(installment.paidAmount),
      initialNextVisitText: _initialNextVisit,
      onSubmit: _handleSubmit,
    );
  }
}
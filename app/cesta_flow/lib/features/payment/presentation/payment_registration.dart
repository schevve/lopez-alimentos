import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/shared/registration_success_screen.dart';
import 'package:cesta_flow/features/sale/presentation/sale_customer_selection.dart';
import 'package:cesta_flow/features/shared/app_text_form_field.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class PaymentRegistration extends StatefulWidget {
  final int saleId;

  const PaymentRegistration({super.key, required this.saleId});

  @override
  State<PaymentRegistration> createState() => _PaymentRegistration();
}

class _PaymentRegistration extends State<PaymentRegistration> {
  static const _paymentMethods = [
    'Pix',
    'Cartão',
    'Dinheiro',
    'Vale de alimentação',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nextVisitController = TextEditingController();
  final _saleRepository = SaleRepository();
  final _installmentRepository = InstallmentRepository();
  final _customerRepository = CustomerRepository();

  Sale? _sale;
  Customer? _customer;
  double _nextInstallmentAmount = 0;
  double _remainingBalance = 0;
  String? _paymentMethod;
  bool _loading = true;
  bool _isSubmitting = false;
  String? _loadError;
  int _unpaidInstallmentsCount = 0;

  bool get _showNextVisitField => _unpaidInstallmentsCount > 1;

  @override
  void initState() {
    super.initState();
    _nextVisitController.text = _formatDate(_oneMonthFromNow());
    _loadSale();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nextVisitController.dispose();
    super.dispose();
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
        _amountController.text = formatMoneyField(nextInstallment);
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

  bool _sameMoney(double a, double b) => (a * 100).round() == (b * 100).round();

  void _applySuggestedAmount(double amount) {
    setState(() {
      _amountController.text = formatMoneyField(amount);
    });
  }

  DateTime _oneMonthFromNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, now.day);
  }

  List<({String label, DateTime date})> get _suggestedVisitOptions {
    final now = DateTime.now();
    return [
      (label: '1 semana', date: now.add(const Duration(days: 7))),
      (label: '2 semanas', date: now.add(const Duration(days: 14))),
      (label: '1 mês', date: _oneMonthFromNow()),
    ];
  }

  void _applySuggestedVisitDate(DateTime date) {
    setState(() {
      _nextVisitController.text = _formatDate(date);
    });
  }

  ButtonStyle get _suggestedAmountButtonStyle => OutlinedButton.styleFrom(
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
    side: const BorderSide(color: AppColors.secondary, width: 2),
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xffF3FCF3),
          appBar: const TopBar(pagTitle: 'Registrar pagamento'),
          body: _buildBody(),
        ),
        if (_isSubmitting) ...[
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          const Center(child: _PaymentRegistrationLoading()),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _MessageState(
        message: _loadError!,
        actionLabel: 'Tentar novamente',
        onAction: _loadSale,
      );
    }
    final sale = _sale;
    if (sale == null) {
      return const _MessageState(message: 'Venda não encontrada.');
    }
    if (SaleRepository.isSaleFullyPaid(sale) || _remainingBalance <= 0) {
      return const _MessageState(message: 'Esta venda já está quitada.');
    }

    final customer = _customer;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    "Dados da venda",
                    style: TextStyle(
                      color: AppColors.greenText,
                      fontWeight: FontWeight(900),
                      fontSize: 20,
                    ),
                  ),

                  Text(
                    "Cliente",
                    style: TextStyle(
                      color: AppColors.greenText,
                      fontWeight: FontWeight(900),
                    ),
                  ),
                  CustomerSelectionCard(
                    name: customer?.name ?? 'Cliente #${sale.customerId}',
                    cpf: customer?.documentCPF,
                    showInitials: customer != null,
                    borderColor: AppColors.primary,
                  ),
                  Text(
                    "Data da compra",
                    style: TextStyle(
                      color: AppColors.greenText,
                      fontWeight: FontWeight(900),
                    ),
                  ),
                  AppTextFormField(
                    labelText: 'Data da compra',
                    initialValue: _formatDate(sale.createdAt),
                    readOnly: true,
                  ),
                  Text(
                    "Valor do pagamento (R\$)",
                    style: TextStyle(
                      color: AppColors.greenText,
                      fontWeight: FontWeight(900),
                    ),
                  ),
                  AppTextFormField(
                    controller: _amountController,
                    labelText: 'Valor do pagamento *',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [FormatMoney()],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o valor recebido';
                      }
                      if (parseMoneyField(value) <= 0) {
                        return 'O valor deve ser maior que zero';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _applySuggestedAmount(_nextInstallmentAmount),
                    style: _suggestedAmountButtonStyle,
                    child: Text(
                      formatCurrency(_nextInstallmentAmount),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (!_sameMoney(_nextInstallmentAmount, _remainingBalance))
                    OutlinedButton(
                      onPressed: () => _applySuggestedAmount(_remainingBalance),
                      style: _suggestedAmountButtonStyle,
                      child: Text(
                        formatCurrency(_remainingBalance),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
            FormField<String>(
              initialValue: _paymentMethod,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione a forma de pagamento';
                }
                return null;
              },
              builder: (field) {
                final selected = field.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    const Text(
                      'Forma de pagamento *',
                      style: TextStyle(
                        color: AppColors.greenText,
                        fontWeight: FontWeight(900),
                        fontSize: 20,
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 3.5,
                      children: _paymentMethods.map((method) {
                        final isSelected = selected == method;

                        return OutlinedButton(
                          onPressed: () {
                            field.didChange(method);
                            setState(() {
                              _paymentMethod = method;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected
                                ? const Color(0xff1C5631)
                                : Colors.white,
                            foregroundColor: isSelected
                                ? Colors.white
                                : const Color(0xff1C5631),
                            side: const BorderSide(color: Color(0xff1C5631)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(method),
                        );
                      }).toList(),
                    ),
                    if (field.hasError)
                      Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (_showNextVisitField)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    Text(
                      'Próxima visita',
                      style: TextStyle(
                        color: AppColors.greenText,
                        fontWeight: FontWeight(900),
                      ),
                    ),
                    AppTextFormField(
                      controller: _nextVisitController,
                      labelText: 'Próxima visita *',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [FormatDate()],
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Informe a data da próxima visita';
                        }
                        if (text.length < 10) return 'Informe a data completa';
                        if (parseDateField(text) == null) {
                          return 'Data inválida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          for (final option in _suggestedVisitOptions)
                            OutlinedButton(
                              onPressed: () =>
                                  _applySuggestedVisitDate(option.date),
                              style: _suggestedAmountButtonStyle,
                              child: Text(
                                option.label,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Registrar pagamento',
                style: TextStyle(color: AppColors.white, fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = parseMoneyField(_amountController.text);
    final nextVisitText = _showNextVisitField
        ? _nextVisitController.text.trim()
        : '';
    final nextDueDate = _showNextVisitField
        ? parseDateField(nextVisitText)
        : null;
    if (_showNextVisitField && nextDueDate == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _installmentRepository.registerPayment(
        saleId: widget.saleId,
        amount: amount,
        paymentMethod: _paymentMethod,
      );
      if (nextDueDate != null) {
        await _installmentRepository.rescheduleRemainingUnpaidInstallments(
          saleId: widget.saleId,
          firstDueDate: nextDueDate,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RegistrationSuccessScreen(
            message: 'Pagamento registrado!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível registrar o pagamento: $error'),
        ),
      );
    }
  }
}

class _PaymentRegistrationLoading extends StatelessWidget {
  const _PaymentRegistrationLoading();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Registrando pagamento...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

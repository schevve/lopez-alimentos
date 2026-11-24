import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/features/sale/presentation/sale_customer_selection.dart';
import 'package:cesta_flow/features/shared/app_text_form_field.dart';
import 'package:flutter/material.dart';

class PaymentSubmitData {
  const PaymentSubmitData({
    required this.amount,
    required this.paymentMethod,
    this.nextVisitDate,
  });

  final double amount;
  final String paymentMethod;
  final DateTime? nextVisitDate;
}

class PaymentForm extends StatefulWidget {
  const PaymentForm({
    super.key,
    required this.sale,
    required this.customer,
    required this.buttonText,
    required this.submitLoadingMessage,
    required this.suggestedAmount,
    required this.remainingBalance,
    required this.showNextVisitField,
    required this.onSubmit,
    this.initialPaymentMethod,
    this.initialAmountText,
    this.initialNextVisitText,
  });

  final Sale sale;
  final Customer? customer;
  final String buttonText;
  final String submitLoadingMessage;
  final double suggestedAmount;
  final double remainingBalance;
  final bool showNextVisitField;
  final Future<void> Function(PaymentSubmitData data) onSubmit;
  final String? initialPaymentMethod;
  final String? initialAmountText;
  final String? initialNextVisitText;

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  static const _paymentMethods = [
    'Pix',
    'Cartão',
    'Dinheiro',
    'Vale de alimentação',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nextVisitController = TextEditingController();

  String? _paymentMethod;
  bool _isSubmitting = false;

  ButtonStyle get _suggestedAmountButtonStyle => OutlinedButton.styleFrom(
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
    side: const BorderSide(color: AppColors.secondary, width: 2),
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  );

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.initialPaymentMethod;
    _amountController.text =
        widget.initialAmountText ?? formatMoneyField(widget.suggestedAmount);
    _nextVisitController.text =
        widget.initialNextVisitText ?? _formatDate(_oneMonthFromNow());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nextVisitController.dispose();
    super.dispose();
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  bool _sameMoney(double a, double b) => (a * 100).round() == (b * 100).round();

  void _applySuggestedAmount(double amount) {
    setState(() {
      _amountController.text = formatMoneyField(amount);
    });
  }

  void _applySuggestedVisitDate(DateTime date) {
    setState(() {
      _nextVisitController.text = _formatDate(date);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = parseMoneyField(_amountController.text);
    final nextVisitText = widget.showNextVisitField
        ? _nextVisitController.text.trim()
        : '';
    final nextDueDate = widget.showNextVisitField
        ? parseDateField(nextVisitText)
        : null;
    if (widget.showNextVisitField && nextDueDate == null) return;

    final method = _paymentMethod;
    if (method == null || method.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        PaymentSubmitData(
          amount: amount,
          paymentMethod: method,
          nextVisitDate: nextDueDate,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final customer = widget.customer;

    return Stack(
      children: [
        SingleChildScrollView(
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
                      const Text(
                        'Dados da venda',
                        style: TextStyle(
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const Text(
                        'Cliente',
                        style: TextStyle(
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      CustomerSelectionCard(
                        name: customer?.name ?? 'Cliente #${sale.customerId}',
                        cpf: customer?.documentCPF,
                        showInitials: customer != null,
                        borderColor: AppColors.primary,
                      ),
                      const Text(
                        'Data da compra',
                        style: TextStyle(
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      AppTextFormField(
                        labelText: 'Data da compra',
                        initialValue: _formatDate(sale.createdAt),
                        readOnly: true,
                      ),
                      const Text(
                        'Valor do pagamento (R\$)',
                        style: TextStyle(
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w900,
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
                            _applySuggestedAmount(widget.suggestedAmount),
                        style: _suggestedAmountButtonStyle,
                        child: Text(
                          formatCurrency(widget.suggestedAmount),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (!_sameMoney(
                        widget.suggestedAmount,
                        widget.remainingBalance,
                      ))
                        OutlinedButton(
                          onPressed: () =>
                              _applySuggestedAmount(widget.remainingBalance),
                          style: _suggestedAmountButtonStyle,
                          child: Text(
                            formatCurrency(widget.remainingBalance),
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
                            fontWeight: FontWeight.w900,
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
                                side: const BorderSide(
                                  color: Color(0xff1C5631),
                                ),
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
                if (widget.showNextVisitField)
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
                        const Text(
                          'Próxima visita',
                          style: TextStyle(
                            color: AppColors.greenText,
                            fontWeight: FontWeight.w900,
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
                  child: Text(
                    widget.buttonText,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isSubmitting) ...[
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          Center(
            child: _PaymentFormLoading(message: widget.submitLoadingMessage),
          ),
        ],
      ],
    );
  }
}

class PaymentFormMessageState extends StatelessWidget {
  const PaymentFormMessageState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

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

class _PaymentFormLoading extends StatelessWidget {
  const _PaymentFormLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            Text(
              message,
              style: const TextStyle(
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
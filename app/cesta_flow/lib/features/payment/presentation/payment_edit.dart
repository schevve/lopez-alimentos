import 'package:cesta_flow/core/app_data_refresh.dart';
import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/sale/presentation/sale_customer_selection.dart';
import 'package:cesta_flow/features/shared/app_text_form_field.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _suggestedPaymentDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _nextVisitController = TextEditingController();

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
  bool _loading = true;
  bool _isSubmitting = false;
  String? _loadError;
  bool _isPaidInstallment = false;

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
    _dueDateController.text = _formatDate(_oneMonthFromNow());
    _nextVisitController.text = _formatDate(_oneMonthFromNow());
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _suggestedPaymentDateController.dispose();
    _dueDateController.dispose();
    _nextVisitController.dispose();
    super.dispose();
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
      final showNextVisit = unpaidCount > 1;
      String? nextVisit;
      if (showNextVisit) {
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
        _showNextVisitField = showNextVisit;
        _amountController.text = formatMoneyField(installment.expectedAmount);
        _dueDateController.text = installment.dueDate == null
            ? _formatDate(_oneMonthFromNow())
            : _formatDate(installment.dueDate!);
        _suggestedPaymentDateController.text =
            installment.indicatedPaymentDate == null
            ? ''
            : _formatDate(installment.indicatedPaymentDate!);
        _nextVisitController.text =
            nextVisit ?? _formatDate(_oneMonthFromNow());
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

  DateTime _oneMonthFromNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, now.day);
  }

  List<({String label, DateTime date})> get _suggestedPaymentDateOptions {
    final now = DateTime.now();
    return [
      (label: '1 semana', date: now.add(const Duration(days: 7))),
      (label: '2 semanas', date: now.add(const Duration(days: 14))),
      (label: '1 mês', date: _oneMonthFromNow()),
    ];
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

  void _applySuggestedPaymentDate(DateTime date) {
    setState(() {
      _suggestedPaymentDateController.text = _formatDate(date);
    });
  }

  void _applySuggestedVisitDate(DateTime date) {
    setState(() {
      _nextVisitController.text = _formatDate(date);
    });
  }

  Widget _dateFieldSection({
    required String title,
    required TextEditingController controller,
    required String labelText,
    void Function(DateTime date)? onShortcut,
    List<({String label, DateTime date})> shortcuts = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.greenText,
            fontWeight: FontWeight.w900,
          ),
        ),
        AppTextFormField(
          controller: controller,
          labelText: labelText,
          keyboardType: TextInputType.datetime,
          inputFormatters: [FormatDate()],
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Informe a data completa';
            }
            if (text.length < 10) return 'Informe a data completa';
            if (parseDateField(text) == null) {
              return 'Data inválida';
            }
            return null;
          },
        ),
        if (shortcuts.isNotEmpty && onShortcut != null) ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in shortcuts)
                  OutlinedButton(
                    onPressed: () => onShortcut(option.date),
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
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final installment = _installment;
    final sale = _sale;
    if (installment == null || sale == null) return;

    final amount = parseMoneyField(_amountController.text);
    if (amount > SaleRepository.remainingBalance(sale)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O valor previsto não pode exceder o saldo restante da venda.',
          ),
        ),
      );
      return;
    }

    final suggestedPaymentDate = parseDateField(
      _suggestedPaymentDateController.text.trim(),
    );
    final dueDate = parseDateField(_dueDateController.text.trim());
    if (suggestedPaymentDate == null || dueDate == null) return;

    final nextVisitText = _showNextVisitField
        ? _nextVisitController.text.trim()
        : '';
    final nextVisitDate = _showNextVisitField
        ? parseDateField(nextVisitText)
        : null;
    if (_showNextVisitField && nextVisitDate == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _installmentRepository.updateInstallment(
        installment.copyWith(
          expectedAmount: amount,
          dueDate: dueDate,
          indicatedPaymentDate: suggestedPaymentDate,
        ),
      );
      if (nextVisitDate != null) {
        await _installmentRepository.indicateNextPaymentDate(
          saleId: installment.saleId,
          indicatedDate: nextVisitDate,
        );
      }
      if (!mounted) return;
      notifyAppDataChanged();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o pagamento: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xffF3FCF3),
          appBar: const TopBar(pagTitle: 'Editar pagamento'),
          body: _buildBody(),
        ),
        if (_isSubmitting) ...[
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          const Center(child: _PaymentEditLoading()),
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
        onAction: _load,
      );
    }
    final installment = _installment;
    if (installment == null) {
      return const _MessageState(message: 'Pagamento não encontrado.');
    }
    if (_isPaidInstallment) {
      return const _MessageState(
        message: 'Pagamentos já registrados não podem ser alterados.',
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
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Column(
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
                        'Valor previsto (R\$)',
                        style: TextStyle(
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      AppTextFormField(
                        controller: _amountController,
                        labelText: 'Valor previsto *',
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                _applySuggestedAmount(_suggestedAmount),
                            style: _suggestedAmountButtonStyle,
                            child: Text(
                              formatCurrency(_suggestedAmount),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (!_sameMoney(_suggestedAmount, _remainingBalance))
                            OutlinedButton(
                              onPressed: () =>
                                  _applySuggestedAmount(_remainingBalance),
                              style: _suggestedAmountButtonStyle,
                              child: Text(
                                formatCurrency(_remainingBalance),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  _dateFieldSection(
                    title: 'Data de pagamento prevista',
                    controller: _suggestedPaymentDateController,
                    labelText: 'Data de pagamento prevista *',
                    onShortcut: _applySuggestedPaymentDate,
                    shortcuts: _suggestedPaymentDateOptions,
                  ),
                  _dateFieldSection(
                    title: 'Data de vencimento',
                    controller: _dueDateController,
                    labelText: 'Data de vencimento *',
                  ),
                  if (_showNextVisitField)
                    _dateFieldSection(
                      title: 'Próxima visita',
                      controller: _nextVisitController,
                      labelText: 'Próxima visita *',
                      onShortcut: _applySuggestedVisitDate,
                      shortcuts: _suggestedVisitOptions,
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
                      'Salvar alterações',
                      style: TextStyle(color: AppColors.white, fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentEditLoading extends StatelessWidget {
  const _PaymentEditLoading();

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
              'Salvando pagamento...',
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

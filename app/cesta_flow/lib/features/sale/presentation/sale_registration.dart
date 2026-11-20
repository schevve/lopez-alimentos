import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_basket_input.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/sale/presentation/basket_selection.dart';
import 'package:cesta_flow/features/sale/presentation/sale_customer_selection.dart';
import 'package:cesta_flow/features/sale/presentation/sale_success.dart';
import 'package:cesta_flow/features/shared/app_text_form_field.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SelectedBasketLine {
  SelectedBasketLine({required this.basket, this.quantity = 1});

  final Basket basket;
  int quantity;

  double get subtotal => basket.price * quantity;
}

class SaleRegistration extends StatefulWidget {
  const SaleRegistration({super.key});

  @override
  State<SaleRegistration> createState() => _SaleRegistrationState();
}

class _SaleRegistrationState extends State<SaleRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController(text: '0,00');
  final _dateController = TextEditingController();
  Customer? _selectedCustomer;
  final List<SelectedBasketLine> _basketLines = [];
  bool _totalEditedManually = false;
  bool _isSubmitting = false;
  int _installmentCount = 1;

  @override
  void initState() {
    super.initState();
    _dateController.text = getCurrentFormattedDate();
    _totalController.addListener(_onTotalFieldChanged);
  }

  @override
  void dispose() {
    _totalController.removeListener(_onTotalFieldChanged);
    _totalController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _onTotalFieldChanged() {
    if (_updatingTotalProgrammatically) return;
    _totalEditedManually = true;
  }

  var _updatingTotalProgrammatically = false;

  double get _suggestedTotal =>
      _basketLines.fold(0, (sum, line) => sum + line.subtotal);

  void _syncSuggestedTotal() {
    if (_totalEditedManually) return;
    _updatingTotalProgrammatically = true;
    _totalController.text = formatMoneyField(_suggestedTotal);
    _updatingTotalProgrammatically = false;
  }

  void _useSuggestedTotal() {
    setState(() {
      _totalEditedManually = false;
      _syncSuggestedTotal();
    });
  }

  Future<void> _pickBasket() async {
    final basket = await Navigator.push<Basket>(
      context,
      MaterialPageRoute(builder: (context) => const BasketSelection()),
    );
    if (basket == null || !mounted) return;
    setState(() {
      final existing = _basketLines.indexWhere(
        (line) => line.basket.uuid == basket.uuid,
      );
      if (existing >= 0) {
        _basketLines[existing].quantity++;
      } else {
        _basketLines.add(SelectedBasketLine(basket: basket));
      }
      _syncSuggestedTotal();
    });
  }

  void _changeQuantity(int index, int delta) {
    setState(() {
      final line = _basketLines[index];
      final next = line.quantity + delta;
      if (next <= 0) {
        _basketLines.removeAt(index);
      } else {
        line.quantity = next;
      }
      _syncSuggestedTotal();
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

  ButtonStyle _optionButtonStyle({required bool selected}) =>
      OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xff1C5631) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xff1C5631),
        side: const BorderSide(color: Color(0xff1C5631)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      );

  @override
  Widget build(BuildContext context) {
    final customer = _selectedCustomer;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xffF3FCF3),
          appBar: const TopBar(pagTitle: 'Registrar venda'),
          body: SingleChildScrollView(
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
                          name: customer?.name ?? 'Selecionar cliente',
                          cpf: customer?.documentCPF,
                          showInitials: customer != null,
                          borderColor: AppColors.primary,
                          onTap: () async {
                            final value = await Navigator.push<Customer>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomerSelection(),
                              ),
                            );
                            if (value != null && mounted) {
                              setState(() => _selectedCustomer = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  FormField<void>(
                    validator: (_) {
                      if (_basketLines.isEmpty) {
                        return 'Adicione ao menos uma cesta';
                      }
                      return null;
                    },
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          const Text(
                            'Cestas *',
                            style: TextStyle(
                              color: AppColors.greenText,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _pickBasket,
                              style: _optionButtonStyle(selected: false),
                              child: const Text('Adicionar cesta'),
                            ),
                          ),
                          if (field.hasError)
                            Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          for (var i = 0; i < _basketLines.length; i++)
                            _BasketLineCard(
                              line: _basketLines[i],
                              onDecrement: () => _changeQuantity(i, -1),
                              onIncrement: () => _changeQuantity(i, 1),
                            ),
                        ],
                      );
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      const Text(
                        'Quantidade de parcelas *',
                        style: TextStyle(
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.2,
                        children: [
                          for (var count = 1; count <= 3; count++)
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _installmentCount = count),
                              style: _optionButtonStyle(
                                selected: _installmentCount == count,
                              ),
                              child: Text('$count'),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        const Text(
                          'Data da venda',
                          style: TextStyle(
                            color: AppColors.greenText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        AppTextFormField(
                          controller: _dateController,
                          labelText: 'Data da venda *',
                          keyboardType: TextInputType.datetime,
                          inputFormatters: [FormatDate()],
                          validator: (value) {
                            if (value == null || value.trim().length < 10) {
                              return 'Informe a data da venda';
                            }
                            return null;
                          },
                        ),
                        const Text(
                          'Valor total da venda (R\$)',
                          style: TextStyle(
                            color: AppColors.greenText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        AppTextFormField(
                          controller: _totalController,
                          labelText: 'Valor total da venda *',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [FormatMoney()],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o valor total';
                            }
                            if (parseMoneyField(value) <= 0) {
                              return 'O valor deve ser maior que zero';
                            }
                            return null;
                          },
                        ),
                        if (_basketLines.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton(
                              onPressed: _useSuggestedTotal,
                              style: _suggestedAmountButtonStyle,
                              child: Text(
                                formatCurrency(_suggestedTotal),
                                style: const TextStyle(fontSize: 16),
                              ),
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
                      'Registrar venda',
                      style: TextStyle(color: AppColors.white, fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isSubmitting) ...[
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          const Center(child: _SaleRegistrationLoading()),
        ],
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione um cliente')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final price = parseMoneyField(_totalController.text);
    final saleData = Sale(
      uuid: const Uuid().v4(),
      customerId: _selectedCustomer!.id!,
      customerUuid: _selectedCustomer!.uuid,
      price: price,
      amountPaid: 0,
      installments: _installmentCount,
      createdAt: DateTime.parse(
        _dateController.text.split('/').reversed.join('-'),
      ),
    );
    final lines = [
      for (final line in _basketLines)
        SaleBasketInput.catalog(
          basketUuid: line.basket.uuid,
          quantity: line.quantity,
        ),
    ];

    final dbHelper = DatabaseHelper();
    final salesRepository = SaleRepository(dbHelper: dbHelper);
    final installmentRepository = InstallmentRepository(dbHelper: dbHelper);
    try {
      final saleId = await salesRepository.registerSale(saleData, lines);
      await installmentRepository.createPlannedInstallmentsForSale(
        saleId: saleId,
        count: _installmentCount,
        totalPrice: price,
        firstDueDate: saleData.createdAt,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SaleSuccess(
            valor: saleData.price,
            clienteNome: _selectedCustomer!.name,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível registrar a venda: $error')),
      );
    }
  }
}

class _SaleRegistrationLoading extends StatelessWidget {
  const _SaleRegistrationLoading();

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
              'Registrando venda...',
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

class _BasketLineCard extends StatelessWidget {
  const _BasketLineCard({
    required this.line,
    required this.onDecrement,
    required this.onIncrement,
  });

  final SelectedBasketLine line;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            line.basket.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.greenText,
            ),
          ),
          Text(
            '${formatCurrency(line.basket.price)} · Subtotal ${formatCurrency(line.subtotal)}',
            style: const TextStyle(color: AppColors.primary),
          ),
          Row(
            children: [
              const Text(
                'Quantidade',
                style: TextStyle(
                  color: AppColors.greenText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDecrement,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.primary,
                ),
              ),
              Text('${line.quantity}', style: const TextStyle(fontSize: 18)),
              IconButton(
                onPressed: onIncrement,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

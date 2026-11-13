import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_basket_input.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/sale/presentation/basket_selection.dart';
import 'package:cesta_flow/features/sale/presentation/sale_customer_selection.dart';
import 'package:cesta_flow/features/sale/presentation/sale_success.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _CustomerSection(
                customer: _selectedCustomer,
                onSelect: () async {
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
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _pickBasket,
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            fixedSize: const Size(double.infinity, 64),
                            side: const BorderSide(
                              color: Color(0xff1C5631),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          child: const Text(
                            'Adicionar cesta',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xff1C5631),
                            ),
                          ),
                        ),
                      ),
                      if (field.errorText != null)
                        Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
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
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Data da Venda *'),
                keyboardType: TextInputType.datetime,
                inputFormatters: [FormatDate()],
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Informe a data da venda';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _totalController,
                decoration: InputDecoration(
                  labelText: 'Valor total da venda *',
                  helperText: _totalEditedManually
                      ? 'Sugerido: ${formatCurrency(_suggestedTotal)}'
                      : 'Calculado automaticamente pelas cestas',
                  suffixIcon: _totalEditedManually
                      ? IconButton(
                          tooltip: 'Usar valor sugerido',
                          onPressed:
                              _basketLines.isEmpty ? null : _useSuggestedTotal,
                          icon: const Icon(Icons.refresh),
                        )
                      : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              FilledButton(
                onPressed: _submitForm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.greenButton,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Registrar Venda',
                  style: TextStyle(color: Color(0xff1C5631), fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final price = parseMoneyField(_totalController.text);
    final saleData = Sale(
      uuid: const Uuid().v4(),
      customerId: _selectedCustomer!.id!,
      customerUuid: _selectedCustomer!.uuid,
      price: price,
      amountPaid: 0,
      installments: 1,
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

    final salesRepository = SaleRepository(dbHelper: DatabaseHelper());
    await salesRepository.registerSale(saleData, lines);

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
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.customer, required this.onSelect});

  final Customer? customer;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onSelect,
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              fixedSize: const Size(double.infinity, 64),
              side: const BorderSide(color: Color(0xff1C5631), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: const Text(
              'Selecionar Cliente',
              style: TextStyle(fontSize: 20, color: Color(0xff1C5631)),
            ),
          ),
        ),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Cliente *'),
          child: Text(
            customer == null
                ? 'Nenhum cliente selecionado'
                : '${customer!.name}, CPF: ${formatCpf(customer!.documentCPF)}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              line.basket.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '${formatCurrency(line.basket.price)} · Subtotal ${formatCurrency(line.subtotal)}',
            ),
            Row(
              children: [
                const Text('Quantidade'),
                const Spacer(),
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${line.quantity}', style: const TextStyle(fontSize: 18)),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:flutter/material.dart';

class BasketForm extends StatefulWidget {
  const BasketForm({
    super.key,
    this.basket,
    required this.onSubmit,
    required this.submitLabel,
  });

  final Basket? basket;
  final Future<void> Function(String name, double price) onSubmit;
  final String submitLabel;

  @override
  State<BasketForm> createState() => _BasketFormState();
}

class _BasketFormState extends State<BasketForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final basket = widget.basket;
    _nameController = TextEditingController(text: basket?.name ?? '');
    _priceController = TextEditingController(
      text: basket == null
          ? ''
          : basket.price.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final price = double.parse(
      _priceController.text.replaceAll(',', '.'),
    );

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_nameController.text.trim(), price);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome da cesta *'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome da cesta';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Preço *'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FormatMoney()],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o preço';
              }
              return null;
            },
          ),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
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
              widget.submitLabel,
              style: const TextStyle(color: AppColors.white, fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
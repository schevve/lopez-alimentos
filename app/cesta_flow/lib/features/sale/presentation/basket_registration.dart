import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/repository/basket_repository.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BasketRegistration extends StatefulWidget {
  const BasketRegistration({super.key});

  @override
  State<BasketRegistration> createState() => _BasketRegistrationState();
}

class _BasketRegistrationState extends State<BasketRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3FCF3),
      appBar: const TopBar(pagTitle: 'Cadastrar cesta'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FormatMoney()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o preço';
                  }
                  return null;
                },
              ),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.greenButton,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Salvar cesta',
                  style: TextStyle(color: Color(0xff1C5631), fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(
      _priceController.text.replaceAll(',', '.'),
    );
    final basket = Basket(
      uuid: const Uuid().v4(),
      name: _nameController.text.trim(),
      price: price,
    );
    final repository = BasketRepository(dbHelper: DatabaseHelper());
    final basketId = await repository.registerBasket(basket);
    if (!mounted) return;
    final saved = basket.copyWith(id: basketId);
    Navigator.pop(context, saved);
  }
}

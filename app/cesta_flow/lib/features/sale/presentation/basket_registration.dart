import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/repository/basket_repository.dart';
import 'package:cesta_flow/features/shared/basket_form.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BasketRegistration extends StatelessWidget {
  const BasketRegistration({super.key});

  Future<void> _register(BuildContext context, String name, double price) async {
    final basket = Basket(
      uuid: const Uuid().v4(),
      name: name,
      price: price,
    );
    final repository = BasketRepository(dbHelper: DatabaseHelper());
    final basketId = await repository.registerBasket(basket);
    if (!context.mounted) return;
    Navigator.pop(context, basket.copyWith(id: basketId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3FCF3),
      appBar: const TopBar(pagTitle: 'Cadastrar cesta'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: BasketForm(
          submitLabel: 'Salvar cesta',
          onSubmit: (name, price) => _register(context, name, price),
        ),
      ),
    );
  }
}
import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_basket_input.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Só a liberação administrativa muda o bloqueio de vendas', () async {
    final directory = Directory.systemTemp.createTempSync('customer-override-');
    final store = Store(getObjectBoxModel(), directory: directory.path);
    addTearDown(() {
      store.close();
      directory.deleteSync(recursive: true);
    });

    final helper = DatabaseHelper.withStore(store);
    final customers = CustomerRepository(dbHelper: helper);
    final sales = SaleRepository(dbHelper: helper);
    final customer = Customer.fromMap({
      'id': 'cliente-teste',
      'name': 'Cliente teste',
      'cpf': '12345678901',
      'score': 20,
      'is_blocked': true,
    });

    expect(customer.isAdminUnblocked, isFalse);
    final id = await customers.registerCustomer(
      customer.copyWith(isAdminUnblocked: true),
    );
    final saved = (await customers.getCustomerById(id))!;
    expect(saved.isAdminUnblocked, isFalse);
    await customers.updateCustomer(saved.copyWith(isAdminUnblocked: true));
    await expectLater(
      customers.updateCustomerWithSalesOverride(saved, isAdminUnblocked: true),
      throwsStateError,
    );

    Future<int> registerSale() => sales.registerSale(
      Sale(uuid: 'venda-teste', customerId: id, price: 100),
      [
        SaleBasketInput.unregistered(
          name: 'Cesta',
          unitPrice: 100,
          quantity: 1,
        ),
      ],
    );

    await expectLater(registerSale(), throwsStateError);

    // Simula receber a liberação de um administrador pelo Supabase.
    final remote = Customer.fromMap({
      ...saved.toRemote(),
      'is_admin_unblocked': true,
    }).copyWith(id: id);
    store.box<Customer>().put(remote, mode: PutMode.update);
    await customers.updateCustomer(saved.copyWith(name: 'Nome atualizado'));

    final released = (await customers.getCustomerById(id))!;
    expect(released.isBlocked, isTrue);
    expect(released.isBlockedForSales, isFalse);
    expect(released.toRemote()['is_admin_unblocked'], isTrue);
    expect(await registerSale(), greaterThan(0));

    store.box<Customer>().put(
      released.copyWith(isAdminUnblocked: false),
      mode: PutMode.update,
    );
    await expectLater(registerSale(), throwsStateError);
  });
}

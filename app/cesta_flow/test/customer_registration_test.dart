import 'dart:async';

import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/customer/presentation/customer_registration.dart';
import 'package:cesta_flow/features/customer/presentation/tela_clientes.dart';
import 'package:cesta_flow/features/sale/presentation/sale_customer_selection.dart';
import 'package:cesta_flow/features/shared/customer_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';

class _CustomerRepository extends CustomerRepository {
  final List<Customer> customers = [];
  Object? registerError;
  int registerCalls = 0;

  @override
  Future<int> registerCustomer(Customer customer) async {
    registerCalls++;
    final error = registerError;
    if (error != null) throw error;

    final savedCustomer = customer.copyWith(id: customers.length + 1);
    customers.add(savedCustomer);
    return savedCustomer.id!;
  }

  @override
  Future<Customer?> getCustomerById(int id) async {
    for (final customer in customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  @override
  Future<List<Customer>> getAllCustomers() async => List.of(customers);
}

Future<void> _fillCustomerForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  for (final (index, value) in [
    (0, 'Cliente de teste'),
    (1, '01/01/2000'),
    (3, '(45) 99999-0000'),
    (4, 'Rua das Flores'),
    (5, '10'),
    (6, 'Toledo'),
    (7, 'PR'),
    (9, '12345678901'),
  ]) {
    await tester.ensureVisible(fields.at(index));
    await tester.enterText(fields.at(index), value);
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Finder _submitButton() => find.descendant(
  of: find.byType(CustomerForm),
  matching: find.byType(FilledButton),
);

void main() {
  testWidgets('bloqueia novos envios enquanto o formulário está salvando', (
    tester,
  ) async {
    final save = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerForm(
            onSubmit: (_) {
              calls++;
              return save.future;
            },
            buttonText: 'Registrar cliente',
            title: 'Registrar cliente',
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(6), 'Toledo');
    await tester.enterText(find.byType(TextFormField).at(7), 'PR');

    await tester.ensureVisible(_submitButton());
    await tester.tap(_submitButton());
    await tester.pump();
    expect(find.text('Salvando...'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    expect(calls, 1);

    save.complete();
    await tester.pumpAndSettle();
    expect(find.text('Registrar cliente'), findsOneWidget);
  });

  testWidgets('cadastra e atualiza a seleção usando o mesmo repositório', (
    tester,
  ) async {
    final repository = _CustomerRepository();
    await tester.pumpWidget(
      MaterialApp(home: CustomerSelection(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar novo cliente'));
    await tester.pumpAndSettle();

    await _fillCustomerForm(tester);
    await tester.ensureVisible(_submitButton());
    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(repository.registerCalls, 1);
    expect(find.text('Cliente de teste'), findsOneWidget);
    expect(
      find.text('Cliente de teste cadastrado com sucesso.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exibe mensagem amigável quando o CPF ou RG já existe', (
    tester,
  ) async {
    final repository = _CustomerRepository()
      ..registerError = UniqueViolationException('CPF duplicado');
    await tester.pumpWidget(
      MaterialApp(home: CustomerRegistration(repository: repository)),
    );
    await tester.pumpAndSettle();

    await _fillCustomerForm(tester);
    await tester.ensureVisible(_submitButton());
    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(
      find.text('Já existe um cliente cadastrado com este CPF ou RG.'),
      findsOneWidget,
    );
    expect(find.byType(CustomerRegistration), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trata erros inesperados sem deixar a tela de cadastro', (
    tester,
  ) async {
    final repository = _CustomerRepository()
      ..registerError = StateError('falha de armazenamento');
    await tester.pumpWidget(
      MaterialApp(home: CustomerRegistration(repository: repository)),
    );
    await tester.pumpAndSettle();

    await _fillCustomerForm(tester);
    await tester.ensureVisible(_submitButton());
    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível salvar o cliente. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.byType(CustomerRegistration), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a tela de clientes compartilha o repositório e confirma sucesso',
    (tester) async {
      final repository = _CustomerRepository();
      await tester.pumpWidget(
        MaterialApp(home: ClientesScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Novo Cliente'));
      await tester.pumpAndSettle();

      await _fillCustomerForm(tester);
      await tester.ensureVisible(_submitButton());
      await tester.tap(_submitButton());
      await tester.pumpAndSettle();

      expect(repository.registerCalls, 1);
      expect(
        find.text('Cliente de teste cadastrado com sucesso.'),
        findsOneWidget,
      );
      expect(find.text('Cliente de teste'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

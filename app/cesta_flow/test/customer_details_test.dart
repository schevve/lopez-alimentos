import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/payment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/customer/presentation/customer_details.dart';
import 'package:cesta_flow/features/customer/presentation/customer_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CustomerRepository extends CustomerRepository {
  Customer? customer = Customer(
    id: 5,
    name: 'Cliente de teste',
    dateOfBirth: DateTime(1990, 1, 2),
    phone: '(45) 99999-0000',
    address: 'Rua das Flores, 10',
    city: 'Toledo',
    state: 'PR',
    documentCPF: '123.456.789-01',
  );
  int updates = 0;

  @override
  Future<Customer?> getCustomerById(int id) async =>
      customer?.id == id ? customer : null;

  @override
  Future<int> updateCustomer(Customer updatedCustomer) async {
    customer = updatedCustomer;
    updates++;
    return 1;
  }
}

class _SaleRepository extends SaleRepository {
  @override
  Future<List<Sale>> getSalesByCustomerId(int customerId) async => [
    Sale(
      id: 11,
      customerId: customerId,
      productName: 'Cesta básica',
      price: 50,
      quantity: 2,
      date: DateTime(2026, 10, 1),
      description: '',
    ),
    Sale(
      id: 12,
      customerId: customerId,
      productName: 'Arroz',
      price: 25,
      quantity: 1,
      date: DateTime(2026, 10, 2),
      description: '',
    ),
  ];
}

class _PaymentRepository extends PaymentRepository {
  @override
  Future<Map<int, double>> getPaymentTotalsBySaleIds(List<int> saleIds) async =>
      {11: 40, 12: 25};
}

void main() {
  testWidgets('exibe dados e totais financeiros calculados do cliente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetails(
          customerId: 5,
          customerRepository: _CustomerRepository(),
          saleRepository: _SaleRepository(),
          paymentRepository: _PaymentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cliente de teste'), findsOneWidget);
    expect(find.text('R\$ 125,00'), findsOneWidget);
    expect(find.text('R\$ 65,00'), findsOneWidget);
    expect(find.text('R\$ 60,00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Venda #11'), 400);
    expect(find.text('Venda #11'), findsWidgets);
    expect(find.text('Parcialmente paga'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Venda #12'), 400);
    expect(find.text('Venda #12'), findsOneWidget);
    expect(find.text('Paga'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edita o cadastro existente e atualiza os detalhes ao retornar', (
    tester,
  ) async {
    final customerRepository = _CustomerRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetails(
          customerId: 5,
          customerRepository: customerRepository,
          saleRepository: _SaleRepository(),
          paymentRepository: _PaymentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar cliente'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerRegistration), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .initialValue,
      'Cliente de teste',
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'Cliente atualizado',
    );
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(customerRepository.updates, 1);
    expect(find.text('Cliente atualizado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trata ID inexistente sem falhar', (tester) async {
    final repository = _CustomerRepository()..customer = null;
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetails(
          customerId: 999,
          customerRepository: repository,
          saleRepository: _SaleRepository(),
          paymentRepository: _PaymentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cliente não encontrado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

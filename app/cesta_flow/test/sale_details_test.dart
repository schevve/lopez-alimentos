import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/sale/presentation/sale_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SaleRepository extends SaleRepository {
  Sale? sale = Sale(
    id: 11,
    uuid: 'sale-11',
    customerId: 5,
    price: 100,
    installments: 2,
    createdAt: DateTime(2026, 10, 1),
  );

  @override
  Future<Sale?> getSaleById(int id) async => sale?.id == id ? sale : null;

  @override
  Future<List<SaleBasketLine>> getBasketLines(int saleId) async => [
    const SaleBasketLine(name: 'Cesta básica', price: 50, quantity: 2),
  ];
}

class _InstallmentRepository extends InstallmentRepository {
  @override
  Future<double> paidAmountBySaleId(int saleId) async => saleId == 11 ? 40 : 0;

  @override
  Future<List<Installment>> getInstallmentsBySaleId(int saleId) async => [
    Installment(
      uuid: 'installment-1',
      saleId: saleId,
      amount: 40,
      paymentDate: DateTime(2026, 10, 2),
    ),
    Installment(
      uuid: 'installment-2',
      saleId: saleId,
      amount: 60,
      dueDate: DateTime(2026, 11, 2),
    ),
  ];
}

class _CustomerRepository extends CustomerRepository {
  @override
  Future<Customer?> getCustomerById(int id) async => Customer(
    id: id,
    uuid: 'customer-$id',
    name: 'Cliente de teste',
    dateOfBirth: DateTime(1990, 1, 2),
    phone: '(45) 99999-0000',
    addressNumber: '10',
    address: 'Rua das Flores, 10',
    city: 'Toledo',
    state: 'PR',
    documentCPF: '123.456.789-01',
  );
}

void main() {
  testWidgets('exibe resumo, produto e parcelas da venda', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SaleDetails(
          saleId: 11,
          saleRepository: _SaleRepository(),
          installmentRepository: _InstallmentRepository(),
          customerRepository: _CustomerRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da venda'), findsOneWidget);
    expect(find.text('Venda #11'), findsOneWidget);
    expect(find.text('Cliente de teste'), findsOneWidget);
    expect(find.text('Resumo da venda'), findsOneWidget);
    expect(find.text('Valor da venda'), findsOneWidget);
    expect(find.text('R\$ 100,00'), findsWidgets);
    expect(find.text('Valor pago'), findsOneWidget);
    expect(find.text('R\$ 40,00'), findsOneWidget);
    expect(find.text('Parcelas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Produtos'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cesta básica'), 400);
    expect(find.text('Cesta básica'), findsOneWidget);
    expect(find.text('Valor unitário'), findsOneWidget);
    expect(find.text('R\$ 50,00'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Parcela 2'), 400);
    expect(find.text('Parcela 1'), findsOneWidget);
    expect(find.text('Parcela 2'), findsOneWidget);
    expect(find.text('Paga'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trata ID inexistente sem falhar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SaleDetails(
          saleId: 999,
          saleRepository: _SaleRepository()..sale = null,
          installmentRepository: _InstallmentRepository(),
          customerRepository: _CustomerRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Venda não encontrada.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

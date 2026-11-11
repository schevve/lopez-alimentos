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
    customerId: 5,
    productName: 'Cesta básica',
    price: 50,
    quantity: 2,
    date: DateTime(2026, 10, 1),
    description: 'Entrega na portaria',
  );

  @override
  Future<Sale?> getSaleById(int id) async => sale?.id == id ? sale : null;
}

class _InstallmentRepository extends InstallmentRepository {
  _InstallmentRepository({this.firstPaid = 40, this.secondPaid = 0});

  final double firstPaid;
  final double secondPaid;

  @override
  Future<List<Installment>> getInstallmentsBySaleId(int saleId) async => [
    Installment(
      id: 21,
      saleId: saleId,
      number: 1,
      amount: 50,
      dueDate: DateTime(2026, 11, 1),
      paidAmount: firstPaid,
      paidAt: firstPaid > 0 ? DateTime(2026, 11, 2) : null,
      paymentMethod: firstPaid > 0 ? 'Pix' : null,
    ),
    Installment(
      id: 22,
      saleId: saleId,
      number: 2,
      amount: 50,
      dueDate: DateTime(2026, 12, 1),
      paidAmount: secondPaid,
      paidAt: secondPaid > 0 ? DateTime(2026, 12, 1) : null,
      paymentMethod: secondPaid > 0 ? 'Dinheiro' : null,
    ),
  ];
}

class _CustomerRepository extends CustomerRepository {
  @override
  Future<Customer?> getCustomerById(int id) async => Customer(
    id: id,
    name: 'Cliente de teste',
    dateOfBirth: DateTime(1990, 1, 2),
    phone: '(45) 99999-0000',
    address: 'Rua das Flores, 10',
    adress_number: '10',
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
          customerRepository: _CustomerRepository(),
          installmentRepository: _InstallmentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da venda'), findsOneWidget);
    expect(find.text('Venda #11'), findsOneWidget);
    expect(find.text('Cliente de teste'), findsOneWidget);
    expect(find.text('Parcialmente paga'), findsOneWidget);
    expect(find.text('Resumo da venda'), findsOneWidget);
    expect(find.text('Valor da venda'), findsOneWidget);
    expect(find.text('R\$ 100,00'), findsWidgets);
    expect(find.text('Valor pago'), findsOneWidget);
    expect(find.text('R\$ 40,00'), findsOneWidget);
    expect(find.text('Parcelas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Produtos'), 400);
    expect(find.text('Produtos'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cesta básica'), 400);
    expect(find.text('Cesta básica'), findsOneWidget);
    expect(find.text('Valor unitário'), findsOneWidget);
    expect(find.text('R\$ 50,00'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Parcela 2'), 400);
    expect(find.text('Parcela 1'), findsOneWidget);
    expect(find.text('Parcela 2'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trata ID inexistente sem falhar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SaleDetails(
          saleId: 999,
          saleRepository: _SaleRepository()..sale = null,
          customerRepository: _CustomerRepository(),
          installmentRepository: _InstallmentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Venda não encontrada.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marca a venda quitada quando o total foi recebido', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SaleDetails(
          saleId: 11,
          saleRepository: _SaleRepository(),
          customerRepository: _CustomerRepository(),
          installmentRepository: _InstallmentRepository(
            firstPaid: 50,
            secondPaid: 50,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quitada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

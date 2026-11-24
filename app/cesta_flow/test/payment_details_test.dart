import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/payment/presentation/payment_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _InstallmentRepository extends InstallmentRepository {
  Installment? installment = Installment(
    id: 7,
    uuid: 'installment-7',
    saleId: 11,
    expectedAmount: 60,
    dueDate: DateTime(2026, 11, 2),
    createdAt: DateTime(2026, 10, 1),
  );

  @override
  Future<Installment?> getInstallmentById(int id) async =>
      installment?.id == id ? installment : null;

  @override
  Future<List<Installment>> getInstallmentsBySaleId(int saleId) async => [
    Installment(
      id: 6,
      uuid: 'installment-6',
      saleId: saleId,
      expectedAmount: 40,
      paidAmount: 40,
      paymentDate: DateTime(2026, 10, 2),
    ),
    installment!,
  ];
}

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
  testWidgets('exibe resumo e cabeçalho do pagamento', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentDetails(
          installmentId: 7,
          installmentRepository: _InstallmentRepository(),
          saleRepository: _SaleRepository(),
          customerRepository: _CustomerRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do pagamento'), findsOneWidget);
    expect(find.text('Pagamento #7'), findsOneWidget);
    expect(find.text('Cliente de teste'), findsOneWidget);
    expect(find.text('Resumo do pagamento'), findsOneWidget);
    expect(find.text('Valor previsto'), findsOneWidget);
    expect(find.text('R\$ 60,00'), findsWidgets);
    expect(find.text('Valor pago'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsOneWidget);
    expect(find.text('Parcela 2 de 2'), findsOneWidget);
    expect(find.text('Venda #11'), findsWidgets);
    expect(find.byTooltip('Editar pagamento'), findsOneWidget);
    final editButton = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .firstWhere((button) => button.tooltip == 'Editar pagamento');
    expect(editButton.onPressed, isNotNull);
    expect(find.text('Receber pagamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trata ID inexistente sem falhar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentDetails(
          installmentId: 999,
          installmentRepository: _InstallmentRepository()..installment = null,
          saleRepository: _SaleRepository(),
          customerRepository: _CustomerRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pagamento não encontrado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
import 'package:cesta_flow/core/constants/util/format_date.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';
import 'package:cesta_flow/core/domain/installment_due_date.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingController _controllerFor(WidgetTester tester, String label) {
  return tester
      .widget<TextFormField>(find.widgetWithText(TextFormField, label))
      .controller!;
}

void main() {
  testWidgets('primeira cobrança sugere um mês após a data da venda', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SaleRegistration()));
    await tester.pumpAndSettle();

    final saleDate = parseDateField(
      _controllerFor(tester, 'Data da venda *').text,
    );
    expect(saleDate, isNotNull);
    expect(
      _controllerFor(tester, 'Data da primeira cobrança *').text,
      formatDateFromDateTime(nextInstallmentDueDate(saleDate: saleDate!)),
    );
  });

  testWidgets('primeira cobrança acompanha a venda até ser editada', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SaleRegistration()));
    await tester.pumpAndSettle();

    final saleDateField = find.widgetWithText(TextFormField, 'Data da venda *');
    final firstDueDateField = find.widgetWithText(
      TextFormField,
      'Data da primeira cobrança *',
    );

    await tester.ensureVisible(saleDateField);
    await tester.enterText(saleDateField, '10/03/2026');
    await tester.pumpAndSettle();
    expect(
      _controllerFor(tester, 'Data da primeira cobrança *').text,
      '10/04/2026',
    );

    await tester.ensureVisible(firstDueDateField);
    await tester.enterText(firstDueDateField, '15/04/2026');
    await tester.pumpAndSettle();

    await tester.enterText(saleDateField, '05/03/2026');
    await tester.pumpAndSettle();
    expect(
      _controllerFor(tester, 'Data da primeira cobrança *').text,
      '15/04/2026',
    );
  });
}

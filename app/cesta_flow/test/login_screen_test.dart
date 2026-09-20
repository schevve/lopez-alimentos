import 'package:cesta_flow/main.dart';
import 'package:cesta_flow/features/dashboard/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Valida campos, aplica máscara e navega após preencher', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MainApp());
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Informe seu CPF.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.first, '12345645678');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '123.456.456-78',
    );
    await tester.enterText(campos.last, 'senha-de-teste');
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    await tester.tap(find.byTooltip('Ocultar senha'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

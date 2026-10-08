import 'package:cesta_flow/features/auth/presentation/tela_clientes.dart';
import 'package:cesta_flow/features/auth/presentation/widgets/cliente_card.dart';

import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrirTela(
    WidgetTester tester, {
    Widget home = const ClientesScreen(),
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
  }

  testWidgets(
    'Busca parcial ignora maiúsculas, mostra vazio e restaura a lista',
    (tester) async {
      await abrirTela(tester);
      expect(find.text('Rosângela Batista'), findsOneWidget);
      expect(find.text('Verde (940)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'pErEi');
      await tester.pump();
      expect(find.byType(ClienteCard), findsOneWidget);
      expect(find.text('Ângelo Pereira de Souza'), findsOneWidget);
      expect(find.text('Rosângela Batista'), findsNothing);

      await tester.enterText(find.byType(TextField), 'cliente inexistente');
      await tester.pump();
      expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
      expect(find.byType(ClienteCard), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Rosângela Batista'), findsOneWidget);
      expect(find.text('Ângelo Pereira de Souza'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ações usam o cliente filtrado e abas atualizam a seleção', (
    tester,
  ) async {
    final mensagens = <String?>[];
    final printOriginal = debugPrint;
    debugPrint = (String? mensagem, {int? wrapWidth}) =>
        mensagens.add(mensagem);
    try {
      await abrirTela(tester, home: const Dashboard());
      await tester.tap(find.text('Meus Clientes'));
      await tester.pumpAndSettle();
      expect(find.byType(ClientesScreen), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        1,
      );

      await tester.enterText(find.byType(TextField), 'JANAINA');
      await tester.pump();
      await tester.ensureVisible(find.text('Ver Perfil'));
      await tester.tap(find.text('Ver Perfil'));
      await tester.tap(find.text('Novo Cliente'));

      expect(
        mensagens,
        containsAll([
          'Ver Perfil: Janaína Gonçalves',
          'Navegar para tela de cadastro',
        ]),
      );

      for (final (indice, aba) in [
        (0, 'Início'),
        (2, 'Vendas'),
        (3, 'Perfil'),
        (1, 'Clientes'),
      ]) {
        await tester.tap(find.text(aba));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .currentIndex,
          indice,
        );
        expect(mensagens, contains('Aba selecionada: $aba'));
      }
      expect(find.text('Janaína Gonçalves'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugPrint = printOriginal;
    }
  });
  testWidgets('Busca CPF e combina filtros por score', (tester) async {
    await abrirTela(tester);
    await tester.enterText(find.byType(TextField), '23456789012');
    await tester.pumpAndSettle();
    expect(find.text('Ângelo Pereira de Souza'), findsOneWidget);
    expect(find.text('Rosângela Batista'), findsNothing);
    await tester.tap(find.text('Score Verde'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Rosângela Batista'), findsOneWidget);
    expect(find.text('Ângelo Pereira de Souza'), findsNothing);
    await tester.tap(find.byTooltip('Filtrar clientes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Bloqueados'));
    await tester.pumpAndSettle();
    expect(find.text('José Aparecido dos Santos'), findsOneWidget);
    expect(find.text('Bloqueado p/ Crédito'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Ocupa a janela e reorganiza cartões sem overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1440, 900),
      const Size(1920, 1080),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(key: UniqueKey(), home: const ClientesScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Scaffold)).width, size.width);
      final primeiro = tester.getRect(find.byType(ClienteCard).at(0));
      if (size.width >= 768) {
        final segundo = tester.getRect(find.byType(ClienteCard).at(1));
        expect(primeiro.top, segundo.top);
        expect(segundo.left, greaterThan(primeiro.right));
      } else if (size.width < 600) {
        expect(primeiro.width, greaterThan(size.width * .85));
      }
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Tamanho: $size');
    }
  });

  testWidgets('Fontes ampliadas e teclado permitem rolar e acessar ações', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const ClientesScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.enterText(find.byType(TextField), 'JANAINA');
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nova Venda'));
    await tester.pumpAndSettle();
    expect(find.text('Nova Venda').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

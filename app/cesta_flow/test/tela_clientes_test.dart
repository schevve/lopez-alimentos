import 'dart:async';

import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/customer/presentation/customer_registration.dart';
import 'package:cesta_flow/features/customer/presentation/tela_clientes.dart';
import 'package:cesta_flow/features/customer/presentation/widgets/cliente_card.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/shared/bottom_bar.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Customer cliente(String nome, String cpf, {int? score}) => Customer(
  name: nome,
  dateOfBirth: DateTime(1990, 1, 1),
  phone: '(45) 99999-0000',
  address: 'Rua das Flores, 10',
  city: 'São Paulo',
  state: 'SP',
  documentCPF: cpf,
  score: score,
);

class RepositorioDeTeste extends CustomerRepository {
  List<Customer> clientes = [
    cliente('Rosângela Batista', '123.456.789-01'),
    cliente('Ângelo Pereira', '234.567.890-12', score: 0),
    cliente('Janaína Gonçalves', '345.678.901-23', score: 940),
  ];
  int consultas = 0;
  bool falhar = false;
  Completer<List<Customer>>? pendente;

  @override
  Future<List<Customer>> getAllCustomers() async {
    consultas++;
    if (falhar) throw StateError('Falha de teste');
    return pendente != null ? pendente!.future : List.of(clientes);
  }
}

void main() {
  Future<void> abrirTela(
    WidgetTester tester,
    RepositorioDeTeste repository, {
    Size tamanho = const Size(390, 844),
  }) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ClientesScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Consulta o repositório, usa barras compartilhadas e exibe score nulo',
    (tester) async {
      final repository = RepositorioDeTeste();
      await abrirTela(tester, repository);
      expect(repository.consultas, 1);
      expect(find.byType(TopBar), findsOneWidget);
      expect(find.byType(BottomBar), findsOneWidget);
      expect(find.text('Score não informado'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ROSANGELA');
      await tester.pumpAndSettle();
      expect(find.byType(ClienteCard), findsOneWidget);
      expect(find.text('Rosângela Batista'), findsOneWidget);
      expect(repository.consultas, 1);
      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pumpAndSettle();
      expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Combina busca por CPF com Com score e Sem score, incluindo zero',
    (tester) async {
      await abrirTela(tester, RepositorioDeTeste());
      await tester.enterText(find.byType(TextField), '23456789012');
      await tester.tap(find.text('Com score'));
      await tester.pumpAndSettle();
      expect(find.text('Ângelo Pereira'), findsOneWidget);
      expect(find.text('Score: 0'), findsOneWidget);
      await tester.tap(find.byTooltip('Filtrar clientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Sem score'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Rosângela Batista'), findsOneWidget);
      expect(find.text('Ângelo Pereira'), findsNothing);
      expect(find.text('Score não informado'), findsOneWidget);
      await tester.tap(find.text('Todos'));
      await tester.enterText(find.byType(TextField), 'janaina');
      await tester.pumpAndSettle();
      expect(find.text('Score: 940'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Novo Cliente abre cadastro e atualiza a lista ao voltar', (
    tester,
  ) async {
    final repository = RepositorioDeTeste();
    await abrirTela(tester, repository);
    await tester.tap(find.text('Novo Cliente'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerRegistration), findsOneWidget);
    repository.clientes.add(cliente('Cliente cadastrado', '456.789.012-34'));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(repository.consultas, 2);
    await tester.enterText(find.byType(TextField), 'cadastrado');
    await tester.pumpAndSettle();
    expect(find.text('Cliente cadastrado'), findsOneWidget);
    expect(find.text('Score não informado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Navegação compartilhada abre o Dashboard', (tester) async {
    await abrirTela(tester, RepositorioDeTeste());
    await tester.tap(
      find.descendant(
        of: find.byType(BottomBar),
        matching: find.byIcon(Icons.home),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dashboard), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(ClientesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exibe carregamento e permite tentar novamente após erro', (
    tester,
  ) async {
    final repository = RepositorioDeTeste()
      ..pendente = Completer<List<Customer>>();
    await tester.pumpWidget(
      MaterialApp(home: ClientesScreen(repository: repository)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.pendente!.completeError(StateError('Falha de teste'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar os clientes.'), findsOneWidget);
    repository.pendente = null;
    repository.clientes.clear();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(repository.consultas, 2);
    expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cartões funcionam em celulares em pé', (tester) async {
    for (final tamanho in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await abrirTela(tester, RepositorioDeTeste(), tamanho: tamanho);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tamanho');
    }
  });
}

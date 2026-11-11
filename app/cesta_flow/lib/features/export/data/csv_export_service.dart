import 'dart:convert';
import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:path_provider/path_provider.dart';

class CsvExportService {
  CsvExportService({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;

  static const _columns = [
    'venda_id',
    'venda_data',
    'produto',
    'preco_unitario',
    'quantidade',
    'descricao',
    'cliente_id',
    'cliente_nome',
    'cliente_data_nascimento',
    'cliente_email',
    'cliente_telefone',
    'cliente_endereco',
    'cliente_cidade',
    'cliente_estado',
    'cliente_cep',
    'cliente_cpf',
    'cliente_rg',
  ];

  Future<File> exportDatabase() async {
    final db = await _dbHelper.database;
    final sales = await db.query('sales', orderBy: 'id');
    final customers = await db.query('customers', orderBy: 'id');
    final installments = await db.query(
      'installments',
      orderBy: 'sale_id, number, id',
    );
    final customersById = {
      for (final customer in customers) customer['id']: customer,
    };
    final installmentsBySaleId = <Object?, List<Map<String, Object?>>>{};
    for (final installment in installments) {
      installmentsBySaleId
          .putIfAbsent(installment['sale_id'], () => [])
          .add(installment);
    }

    final maxInstallments = installmentsBySaleId.values.fold<int>(
      0,
      (max, saleInstallments) =>
          saleInstallments.length > max ? saleInstallments.length : max,
    );
    final rows = <List<Object?>>[
      [..._columns, ..._installmentColumns(maxInstallments)],
    ];
    for (final sale in sales) {
      final customer = customersById[sale['customer_id']];
      final saleInstallments = installmentsBySaleId[sale['id']] ?? [];
      rows.add(_saleRow(sale, customer, saleInstallments, maxInstallments));
    }

    final csv = rows.map((row) => row.map(_escape).join(',')).join('\r\n');
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/cesta-flow-export-$timestamp.csv');
    return file.writeAsString('\uFEFF$csv', encoding: utf8);
  }

  List<Object?> _saleRow(
    Map<String, Object?> sale,
    Map<String, Object?>? customer,
    List<Map<String, Object?>> installments,
    int installmentCount,
  ) {
    final row = <Object?>[
      sale['id'],
      sale['date'],
      sale['product_name'],
      sale['price'],
      sale['quantity'],
      sale['description'],
      customer?['id'] ?? sale['customer_id'],
      customer?['name'],
      customer?['date_of_birth'],
      customer?['email'],
      customer?['phone'],
      customer?['address'],
      customer?['city'],
      customer?['state'],
      customer?['cep'],
      customer?['document_cpf'],
      customer?['document_rg'],
    ];

    for (var index = 0; index < installmentCount; index++) {
      final installment = index < installments.length
          ? installments[index]
          : null;
      row.addAll([
        installment?['amount'],
        installment?['paid_amount'],
        installment?['paid_at'],
        installment?['payment_method'],
      ]);
    }

    return row;
  }

  List<String> _installmentColumns(int count) => [
    for (var index = 1; index <= count; index++) ...[
      'parcela_${index}_valor_sugerido',
      'parcela_${index}_valor_pago',
      'parcela_${index}_data_pagamento',
      'parcela_${index}_forma_pagamento',
    ],
  ];

  String _escape(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }
}

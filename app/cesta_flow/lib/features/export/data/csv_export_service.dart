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
    ..._paymentColumns,
  ];

  static const _paymentColumns = [
    'pagamento_1_metodo',
    'pagamento_1_valor',
    'pagamento_1_data',
    'pagamento_2_metodo',
    'pagamento_2_valor',
    'pagamento_2_data',
    'pagamento_3_metodo',
    'pagamento_3_valor',
    'pagamento_3_data',
    'pagamento_4_metodo',
    'pagamento_4_valor',
    'pagamento_4_data',
    'pagamento_5_metodo',
    'pagamento_5_valor',
    'pagamento_5_data',
    'pagamento_6_metodo',
    'pagamento_6_valor',
    'pagamento_6_data',
  ];

  Future<File> exportDatabase() async {
    final db = await _dbHelper.database;
    final sales = await db.query('sales', orderBy: 'id');
    final customers = await db.query('customers', orderBy: 'id');
    final payments = await db.query('payments', orderBy: 'id');
    final customersById = {
      for (final customer in customers) customer['id']: customer,
    };
    final paymentsBySaleId = <Object?, List<Map<String, Object?>>>{};
    for (final payment in payments) {
      final saleId = payment['sale_id'];
      if (saleId != null) {
        paymentsBySaleId.putIfAbsent(saleId, () => []).add(payment);
      }
    }

    final rows = <List<Object?>>[_columns];
    for (final sale in sales) {
      final customer = customersById[sale['customer_id']];
      final salePayments = paymentsBySaleId[sale['id']] ?? [];
      rows.add(_saleRow(sale, customer, salePayments));
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
    List<Map<String, Object?>> payments,
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

    for (var index = 0; index < 6; index++) {
      final payment = index < payments.length ? payments[index] : null;
      row.addAll([payment?['method'], payment?['amount'], payment?['date']]);
    }

    return row;
  }

  String _escape(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }
}

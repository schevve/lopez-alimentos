import 'dart:convert';
import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_basket_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';

class CsvExportService {
  CsvExportService({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;

  static const _columns = [
    'venda_id',
    'venda_data',
    'cesta',
    'preco_cesta',
    'quantidade',
    'preco_venda',
    'valor_pago',
    'parcelas',
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
    ..._installmentColumns,
  ];

  static const _installmentColumns = [
    'parcela_1_valor',
    'parcela_1_vencimento',
    'parcela_1_pagamento',
    'parcela_2_valor',
    'parcela_2_vencimento',
    'parcela_2_pagamento',
    'parcela_3_valor',
    'parcela_3_vencimento',
    'parcela_3_pagamento',
    'parcela_4_valor',
    'parcela_4_vencimento',
    'parcela_4_pagamento',
    'parcela_5_valor',
    'parcela_5_vencimento',
    'parcela_5_pagamento',
    'parcela_6_valor',
    'parcela_6_vencimento',
    'parcela_6_pagamento',
  ];

  Future<File> exportDatabase() async {
    final db = await _dbHelper.store;
    final (sales, customers, installments, links, baskets) = db
        .runInTransaction(
          TxMode.read,
          () => (
            db.box<Sale>().getAll().map((sale) => sale.toMap()).toList(),
            db.box<Customer>().getAll().map((customer) => customer.toMap()).toList(),
            db.box<Installment>().getAll().map((item) => item.toMap()).toList(),
            db.box<SaleBasket>().getAll().map((link) => link.toMap()).toList(),
            db.box<Basket>().getAll().map((basket) => basket.toMap()).toList(),
          ),
        );
    final customersById = {
      for (final customer in customers) customer['id']: customer,
    };
    final basketsById = {for (final basket in baskets) basket['id']: basket};
    final linksBySaleId = <Object?, List<Map<String, Object?>>>{};
    for (final link in links) {
      linksBySaleId.putIfAbsent(link['sale_id'], () => []).add(link);
    }
    final installmentsBySaleId = <Object?, List<Map<String, Object?>>>{};
    for (final installment in installments) {
      installmentsBySaleId
          .putIfAbsent(installment['sale_id'], () => [])
          .add(installment);
    }

    final rows = <List<Object?>>[_columns];
    for (final sale in sales) {
      final customer = customersById[sale['customer_id']];
      rows.add(
        _saleRow(
          sale,
          customer,
          linksBySaleId[sale['id']] ?? [],
          basketsById,
          installmentsBySaleId[sale['id']] ?? [],
        ),
      );
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
    List<Map<String, Object?>> links,
    Map<Object?, Map<String, Object?>> basketsById,
    List<Map<String, Object?>> installments,
  ) {
    final firstLink = links.isEmpty ? null : links.first;
    final basket = firstLink == null
        ? null
        : basketsById[firstLink['basket_id']];
    final row = <Object?>[
      sale['id'],
      sale['created_at'],
      basket?['name'],
      basket?['price'],
      firstLink?['quantity'],
      sale['price'],
      sale['amount_paid'],
      sale['installments'],
      customer?['id'] ?? sale['customer_id'],
      customer?['name'],
      customer?['date_of_birth'],
      customer?['email'],
      customer?['phone'],
      customer?['address'],
      customer?['city'],
      customer?['state'],
      customer?['cep'],
      customer?['cpf'],
      customer?['rg'],
    ];

    for (var index = 0; index < 6; index++) {
      final installment = index < installments.length
          ? installments[index]
          : null;
      row.addAll([
        installment?['amount'],
        installment?['due_date'],
        installment?['payment_date'],
      ]);
    }

    return row;
  }

  String _escape(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }
}

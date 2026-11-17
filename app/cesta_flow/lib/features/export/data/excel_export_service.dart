import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_basket_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';

class ExcelExportService {
  ExcelExportService({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;

  static const _sheetNames = {
    'clientes',
    'vendas',
    'parcelas',
    'cestas',
    'venda_cestas',
  };

  Future<File> exportDatabase() async {
    final db = await _dbHelper.store;
    final (customers, sales, installments, baskets, saleBaskets) = db
        .runInTransaction(
          TxMode.read,
          () => (
            db
                .box<Customer>()
                .getAll()
                .map((customer) => customer.toMap())
                .toList(),
            db.box<Sale>().getAll().map((sale) => sale.toMap()).toList(),
            db
                .box<Installment>()
                .getAll()
                .map((item) => item.toMap())
                .toList(),
            db.box<Basket>().getAll().map((basket) => basket.toMap()).toList(),
            db
                .box<SaleBasket>()
                .getAll()
                .map((link) => link.toMap())
                .toList(),
          ),
        );

    final excel = Excel.createExcel();
    _writeSheet(excel, 'clientes', customers);
    _writeSheet(excel, 'vendas', sales);
    _writeSheet(excel, 'parcelas', installments);
    _writeSheet(excel, 'cestas', baskets);
    _writeSheet(excel, 'venda_cestas', saleBaskets);

    for (final name in List<String>.from(excel.tables.keys)) {
      if (!_sheetNames.contains(name)) {
        excel.delete(name);
      }
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Não foi possível gerar o arquivo Excel.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/cesta-flow-export-$timestamp.xlsx');
    return file.writeAsBytes(bytes);
  }

  void _writeSheet(
    Excel excel,
    String sheetName,
    List<Map<String, dynamic>> rows,
  ) {
    final sheet = excel[sheetName];
    if (rows.isEmpty) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        TextCellValue('(sem registros)'),
      );
      return;
    }

    final headers = _headersFor(rows);
    for (var column = 0; column < headers.length; column++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
        TextCellValue(headers[column]),
      );
    }

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      for (var column = 0; column < headers.length; column++) {
        final cellValue = _cellValue(row[headers[column]]);
        if (cellValue == null) continue;
        sheet.updateCell(
          CellIndex.indexByColumnRow(
            columnIndex: column,
            rowIndex: rowIndex + 1,
          ),
          cellValue,
        );
      }
    }
  }

  List<String> _headersFor(List<Map<String, dynamic>> rows) {
    final keys = <String>{};
    for (final row in rows) {
      keys.addAll(row.keys);
    }
    final headers = keys.toList()
      ..sort((a, b) {
        if (a == 'id') return -1;
        if (b == 'id') return 1;
        return a.compareTo(b);
      });
    return headers;
  }

  CellValue? _cellValue(Object? value) {
    if (value == null) return null;
    if (value is bool) return BoolCellValue(value);
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    return TextCellValue(value.toString());
  }
}
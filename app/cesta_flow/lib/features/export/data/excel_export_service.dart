import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_basket_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/features/export/data/export_period_filter.dart';
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

  /// [filter] limita vendas, parcelas (pagamentos) e `venda_cestas`. Clientes e
  /// cestas são sempre exportados por completo. Sem filtro, todas as abas vêm
  /// completas.
  Future<File> exportDatabase({ExportPeriodFilter? filter}) async {
    final db = await _dbHelper.store;
    final (
      List<Map<String, dynamic>> customers,
      List<Map<String, dynamic>> sales,
      List<Map<String, dynamic>> installments,
      List<Map<String, dynamic>> baskets,
      List<Map<String, dynamic>> saleBaskets,
    ) data = db.runInTransaction(TxMode.read, () {
      final allCustomers = db.box<Customer>().getAll();
      final allSales = db.box<Sale>().getAll();
      final allInstallments = db.box<Installment>().getAll();
      final allBaskets = db.box<Basket>().getAll();
      final allSaleBaskets = db.box<SaleBasket>().getAll();

      if (filter == null) {
        return (
          allCustomers.map((customer) => customer.toMap()).toList(),
          allSales.map((sale) => sale.toMap()).toList(),
          allInstallments.map((item) => item.toMap()).toList(),
          allBaskets.map((basket) => basket.toMap()).toList(),
          allSaleBaskets.map((link) => link.toMap()).toList(),
        );
      }

      final salesInPeriod = allSales
          .where((sale) => filter.contains(sale.createdAt))
          .toList();
      final saleIdsInPeriod = salesInPeriod
          .map((sale) => sale.id)
          .whereType<int>()
          .toSet();

      final installmentsInPeriod = allInstallments.where((installment) {
        if (saleIdsInPeriod.contains(installment.saleId)) return true;
        final paymentDate = installment.paymentDate;
        return paymentDate != null && filter.contains(paymentDate);
      }).toList();

      final relacionamentoSaleIds = {
        ...saleIdsInPeriod,
        ...installmentsInPeriod.map((installment) => installment.saleId),
      };

      final saleBasketsInPeriod = allSaleBaskets
          .where((link) => relacionamentoSaleIds.contains(link.saleId))
          .toList();

      return (
        allCustomers.map((customer) => customer.toMap()).toList(),
        salesInPeriod.map((sale) => sale.toMap()).toList(),
        installmentsInPeriod.map((item) => item.toMap()).toList(),
        allBaskets.map((basket) => basket.toMap()).toList(),
        saleBasketsInPeriod.map((link) => link.toMap()).toList(),
      );
    });

    final excel = Excel.createExcel();
    _writeSheet(excel, 'clientes', data.$1);
    _writeSheet(excel, 'vendas', data.$2);
    _writeSheet(excel, 'parcelas', data.$3);
    _writeSheet(excel, 'cestas', data.$4);
    _writeSheet(excel, 'venda_cestas', data.$5);

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
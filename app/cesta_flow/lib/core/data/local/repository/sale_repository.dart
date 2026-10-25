import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:sqflite/sqflite.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper;

  SaleRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerSale(Sale sale) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'sales',
      sale.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Sale.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Sale>> getSalesBycustumerId(int custumerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'custumer_id = ?',
      whereArgs: [custumerId],
    );
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getAllSales() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sales');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getLatestSales({int limit = 5}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<double> getTotalSalesAmountSince(DateTime date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COALESCE(SUM(price * quantity), 0) AS total '
      'FROM sales WHERE date >= ?',
      [date.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<int> getPendingCustomersCount() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT COUNT(DISTINCT s.customer_id) AS total
      FROM sales s
      WHERE NOT EXISTS (
        SELECT 1 FROM payments p WHERE p.customer_id = s.customer_id
      )
    ''');
    return (result.first['total'] as num).toInt();
  }

  Future<int> updateSale(Sale sale) async {
    if (sale.id == null) {
      throw ArgumentError('Sale id cannot be null when updating.');
    }
    final db = await _dbHelper.database;
    return await db.update(
      'sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> deleteSale(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }
}

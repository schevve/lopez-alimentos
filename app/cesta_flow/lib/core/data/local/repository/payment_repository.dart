import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/payment_model.dart';
import 'package:sqflite/sqflite.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper;

  PaymentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerPayment(Payment payment) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Payment?> getPaymentById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Payment>> getPaymentsBySaleId(int saleId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<double> getPaymentsBySaleIdAmount(int saleId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'payments',
      columns: ['sum(amount) as total'],
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<int, double>> getPaymentTotalsBySaleIds(List<int> saleIds) async {
    if (saleIds.isEmpty) {
      return {};
    }

    final db = await _dbHelper.database;
    final placeholders = List.filled(saleIds.length, '?').join(', ');
    final result = await db.rawQuery(
      'SELECT sale_id, COALESCE(SUM(amount), 0) AS total '
      'FROM payments WHERE sale_id IN ($placeholders) GROUP BY sale_id',
      saleIds,
    );

    return {
      for (final row in result)
        (row['sale_id'] as num).toInt(): (row['total'] as num).toDouble(),
    };
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('payments');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<int> updatePayment(Payment payment) async {
    if (payment.id == null) {
      throw ArgumentError('Payment id cannot be null when updating.');
    }
    final db = await _dbHelper.database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }
}

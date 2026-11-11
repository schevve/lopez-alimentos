import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:sqflite/sqflite.dart';

class InstallmentRepository {
  final DatabaseHelper _dbHelper;

  InstallmentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerInstallment(Installment installment) async {
    final db = await _dbHelper.database;
    return db.insert(
      'installments',
      installment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Installment>> getInstallmentsBySaleId(int saleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'installments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'number ASC, id ASC',
    );
    return maps.map(Installment.fromMap).toList();
  }
}

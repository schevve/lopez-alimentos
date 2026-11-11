import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/customer_score_updater.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:sqflite/sqflite.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper;

  CustomerRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'customers',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isEmpty) return null;
      await CustomerScoreUpdater.refresh(txn, id);
      final maps = await txn.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      return maps.isEmpty ? null : Customer.fromMap(maps.first);
    });
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final customers = await txn.query('customers', columns: ['id']);
      for (final customer in customers) {
        await CustomerScoreUpdater.refresh(txn, customer['id'] as int);
      }
      final maps = await txn.query('customers');
      return maps.map((map) => Customer.fromMap(map)).toList();
    });
  }

  Future<int> updateCustomer(Customer customer) async {
    if (customer.id == null) {
      throw ArgumentError('Customer id cannot be null when updating.');
    }
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}

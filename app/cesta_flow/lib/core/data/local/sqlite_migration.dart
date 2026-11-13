import 'package:objectbox/objectbox.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

import 'model/customer_model.dart';
import 'model/installment_model.dart';
import 'model/sale_model.dart';
import 'model/migration_state.dart';

/// SQLite permanece instalado apenas para ler a base anterior, sem upgrades.
class SqliteMigration {
  static Future<void> importFile(
    Store store,
    String filename, {
    sqlite.DatabaseFactory? factory,
  }) async {
    if (store.box<MigrationState>().get(1) != null) return;
    final databaseFactory = factory ?? sqlite.databaseFactory;
    if (!await databaseFactory.databaseExists(filename)) {
      importRows(store, customers: [], sales: [], payments: []);
      return;
    }
    final db = await databaseFactory.openDatabase(
      filename,
      options: sqlite.OpenDatabaseOptions(
        readOnly: true,
        singleInstance: false,
      ),
    );
    try {
      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      )).map((row) => row['name']).toSet();
      Future<List<Map<String, Object?>>> rows(String name) async =>
          tables.contains(name) ? db.query(name) : [];
      final customers = await rows('customers');
      final sales = await rows('sales');
      final payments = await rows('payments');
      importRows(store, customers: customers, sales: sales, payments: payments);
    } finally {
      await db.close();
    }
  }

  /// Importação atômica: falhas não deixam registros parcialmente migrados.
  static void importRows(
    Store store, {
    required List<Map<String, dynamic>> customers,
    required List<Map<String, dynamic>> sales,
    required List<Map<String, dynamic>> payments,
  }) {
    store.runInTransaction(TxMode.write, () {
      if (store.box<MigrationState>().get(1) != null) return;
      final customerBox = store.box<Customer>();
      final saleBox = store.box<Sale>();
      final installmentBox = store.box<Installment>();
      if (!customerBox.isEmpty() ||
          !saleBox.isEmpty() ||
          !installmentBox.isEmpty()) {
        throw StateError(
          'O ObjectBox já contém dados sem registro de migração. '
          'A importação foi interrompida para preservar as duas bases.',
        );
      }
      void checkIds(List<Map<String, dynamic>> rows) {
        final ids = <int>{};
        for (final row in rows) {
          final id = row['id'];
          if (id is! int || id <= 0 || !ids.add(id)) {
            throw StateError(
              'A base antiga possui IDs inválidos ou duplicados.',
            );
          }
        }
      }

      checkIds(customers);
      checkIds(sales);
      checkIds(payments);
      customerBox.putMany(customers.map(Customer.fromMap).toList());
      for (final row in sales) {
        final sale = Sale.fromMap(row);
        if (customerBox.get(sale.customerId) == null) {
          throw StateError('Venda ${sale.id} sem cliente correspondente.');
        }
        saleBox.put(sale);
      }
      for (final row in payments) {
        if (row['sale_id'] == null) {
          throw StateError(
            'Pagamento ${row['id']} sem venda definida na base antiga. '
            'É necessário definir o vínculo antes de migrar. O SQLite foi preservado.',
          );
        }
        final installment = Installment.fromMap(row);
        final sale = saleBox.get(installment.saleId);
        if (sale == null) {
          throw StateError('Pagamento ${installment.id} sem venda correspondente.');
        }
        installmentBox.put(
          installment.saleUuid.isEmpty
              ? installment.copyWith(saleUuid: sale.uuid)
              : installment,
        );
      }
      store.box<MigrationState>().put(MigrationState());
    });
  }
}

import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'lopez_alimentos_migrations_',
    );
  });

  tearDown(() async {
    if (database.isOpen) {
      await database.close();
    }
    await temporaryDirectory.delete(recursive: true);
  });

  test('migra a versão 4 para a 6 preservando tabelas e registros', () async {
    database = await _createVersionFourDatabase(temporaryDirectory);
    await _insertVersionFourFixture(database);

    database = await _upgradeToVersionSix(database, temporaryDirectory);

    expect(await database.getVersion(), 6);
    expect(
      await _tableNames(database),
      containsAll(['customers', 'sales', 'payments', 'installments']),
    );
    expect(
      await _columnNames(database, 'customers'),
      containsAll(['score', 'adress_number', 'score_category']),
    );
    expect(
      await _columnNames(database, 'installments'),
      containsAll(['paid_amount', 'paid_at', 'payment_method']),
    );
    expect(
      await _columnNames(database, 'payments'),
      containsAll(['sale_id', 'installment_id']),
    );

    final customers = await database.query('customers');
    final sales = await database.query('sales');
    final payments = await database.query('payments');
    expect(customers, hasLength(1));
    expect(customers.single['name'], 'Cliente fictício');
    expect(customers.single['adress_number'], '');
    expect(sales, hasLength(1));
    expect(sales.single['id'], 1);
    expect(sales.single['price'], 100.0);
    expect(payments, hasLength(1));
    expect(payments.single['id'], 1);
    expect(payments.single['sale_id'], 1);
    expect(payments.single['method'], 'Dinheiro');
    expect(payments.single['date'], '2026-10-02T10:00:00.000');
    expect(await database.query('installments'), hasLength(1));
    expect(payments.single['amount'], 25.0);
  });

  test(
    'migra a versão 5 para a 6 adicionando as colunas de recebimento',
    () async {
      database = await _createVersionFiveDatabase(temporaryDirectory);

      database = await _upgradeToVersionSix(database, temporaryDirectory);

      expect(await database.getVersion(), 6);
      expect(
        await _columnNames(database, 'installments'),
        containsAll(['paid_amount', 'paid_at', 'payment_method']),
      );
    },
  );

  test(
    'agrega pagamentos vinculados e usa data e método mais recentes',
    () async {
      database = await _createVersionFiveDatabase(temporaryDirectory);
      await _insertVersionFiveFixture(database);

      database = await _upgradeToVersionSix(database, temporaryDirectory);

      final installment = (await database.query('installments')).single;
      expect(installment['paid_amount'], 37.5);
      expect(installment['paid_at'], '2026-10-12T10:00:00.000');
      expect(installment['payment_method'], 'Pix');
      expect(await database.query('payments'), hasLength(2));
    },
  );

  test(
    'mantém pagamento antigo sem vínculo, mas ele não reduz o saldo da parcela',
    () async {
      database = await _createVersionFourDatabase(temporaryDirectory);
      await _insertVersionFourFixture(database);

      database = await _upgradeToVersionSix(database, temporaryDirectory);

      final payment = (await database.query('payments')).single;
      final installment = (await database.query('installments')).single;
      final paidByInstallments = await database.rawQuery(
        'SELECT COALESCE(SUM(paid_amount), 0) AS total FROM installments',
      );

      expect(payment['installment_id'], isNull);
      expect(payment['amount'], 25.0);
      expect(installment['paid_amount'], 0.0);
      expect(paidByInstallments.single['total'], 0);
      expect((await database.query('sales')).single['price'], 100.0);
    },
  );

  test(
    'reabrir versão 6 não executa outra migração nem duplica parcelas',
    () async {
      database = await _createVersionFiveDatabase(temporaryDirectory);
      await _insertVersionFiveFixture(database);
      database = await _upgradeToVersionSix(database, temporaryDirectory);

      final beforeInstallments = await database.query('installments');
      final beforePayments = await database.query('payments');
      await database.close();

      var upgradeCalls = 0;
      database = await databaseFactoryFfi.openDatabase(
        path.join(temporaryDirectory.path, 'app_database.db'),
        options: OpenDatabaseOptions(
          version: 6,
          onUpgrade: (db, oldVersion, newVersion) async {
            upgradeCalls++;
            await DatabaseHelper().onUpgrade(db, oldVersion, newVersion);
          },
        ),
      );

      expect(upgradeCalls, 0);
      expect(await database.query('installments'), beforeInstallments);
      expect(await database.query('payments'), beforePayments);
      expect(await database.getVersion(), 6);
    },
  );
}

Future<Database> _createVersionFourDatabase(Directory directory) {
  return databaseFactoryFfi.openDatabase(
    path.join(directory.path, 'app_database.db'),
    options: OpenDatabaseOptions(
      version: 4,
      onCreate: (db, version) async {
        await _createVersionFourSchema(db);
      },
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    ),
  );
}

Future<Database> _createVersionFiveDatabase(Directory directory) {
  return databaseFactoryFfi.openDatabase(
    path.join(directory.path, 'app_database.db'),
    options: OpenDatabaseOptions(
      version: 5,
      onCreate: (db, version) async {
        await _createVersionFiveSchema(db);
      },
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    ),
  );
}

Future<Database> _upgradeToVersionSix(
  Database database,
  Directory directory,
) async {
  await database.close();
  return databaseFactoryFfi.openDatabase(
    path.join(directory.path, 'app_database.db'),
    options: OpenDatabaseOptions(
      version: 6,
      onUpgrade: DatabaseHelper().onUpgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    ),
  );
}

Future<void> _createVersionFourSchema(Database db) async {
  await db.execute('''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      date_of_birth TEXT NOT NULL,
      email TEXT,
      phone TEXT NOT NULL,
      address TEXT NOT NULL,
      city TEXT NOT NULL,
      state TEXT NOT NULL,
      cep TEXT,
      document_cpf TEXT NOT NULL UNIQUE,
      document_rg TEXT UNIQUE
    )
  ''');
  await db.execute('''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      price REAL NOT NULL,
      quantity INTEGER NOT NULL,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      method TEXT NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
    )
  ''');
}

Future<void> _createVersionFiveSchema(Database db) async {
  await db.execute('''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      date_of_birth TEXT NOT NULL,
      email TEXT,
      phone TEXT NOT NULL,
      address TEXT NOT NULL,
      addres_number TEXT NOT NULL,
      city TEXT NOT NULL,
      state TEXT NOT NULL,
      cep TEXT,
      document_cpf TEXT NOT NULL UNIQUE,
      document_rg TEXT UNIQUE,
      score INTEGER,
      score_category TEXT NOT NULL DEFAULT 'yellow',
      authorized INTEGER NOT NULL DEFAULT 0,
      manual_block_override INTEGER
    )
  ''');
  await db.execute('''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      price REAL NOT NULL,
      quantity INTEGER NOT NULL,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE installments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      number INTEGER NOT NULL,
      amount REAL NOT NULL,
      due_date TEXT,
      FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      installment_id INTEGER,
      method TEXT NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
      FOREIGN KEY (installment_id) REFERENCES installments (id) ON DELETE CASCADE
    )
  ''');
}

Future<void> _insertVersionFourFixture(Database db) async {
  await db.insert('customers', {
    'id': 1,
    'name': 'Cliente fictício',
    'date_of_birth': '1990-01-01',
    'email': null,
    'phone': '4500000000',
    'address': 'Rua de teste',
    'city': 'Toledo',
    'state': 'PR',
    'cep': null,
    'document_cpf': '00000000001',
    'document_rg': null,
  });
  await db.insert('sales', {
    'id': 1,
    'customer_id': 1,
    'product_name': 'Cesta de teste',
    'price': 100.0,
    'quantity': 1,
    'date': '2026-10-01T10:00:00.000',
    'description': 'Venda fictícia para teste de migração',
  });
  await db.insert('payments', {
    'id': 1,
    'sale_id': 1,
    'method': 'Dinheiro',
    'amount': 25.0,
    'date': '2026-10-02T10:00:00.000',
  });
}

Future<void> _insertVersionFiveFixture(Database db) async {
  await db.insert('customers', {
    'id': 1,
    'name': 'Cliente fictício',
    'date_of_birth': '1990-01-01',
    'email': null,
    'phone': '4500000000',
    'address': 'Rua de teste',
    'addres_number': '1',
    'city': 'Toledo',
    'state': 'PR',
    'cep': null,
    'document_cpf': '00000000001',
    'document_rg': null,
  });
  await db.insert('sales', {
    'id': 1,
    'customer_id': 1,
    'product_name': 'Cesta de teste',
    'price': 100.0,
    'quantity': 1,
    'date': '2026-10-01T10:00:00.000',
    'description': 'Venda fictícia para teste de migração',
  });
  await db.insert('installments', {
    'id': 1,
    'sale_id': 1,
    'number': 1,
    'amount': 100.0,
    'due_date': '2026-11-01T10:00:00.000',
  });
  await db.insert('payments', {
    'id': 1,
    'sale_id': 1,
    'installment_id': 1,
    'method': 'Dinheiro',
    'amount': 12.5,
    'date': '2026-10-10T10:00:00.000',
  });
  await db.insert('payments', {
    'id': 2,
    'sale_id': 1,
    'installment_id': 1,
    'method': 'Pix',
    'amount': 25.0,
    'date': '2026-10-12T10:00:00.000',
  });
}

Future<Set<String>> _tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  );
  return rows.map((row) => row['name'] as String).toSet();
}

Future<Set<String>> _columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((row) => row['name'] as String).toSet();
}

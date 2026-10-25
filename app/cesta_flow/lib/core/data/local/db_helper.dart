import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Private constructor
  DatabaseHelper._internal();

  // Factory constructor to return the singleton instance
  factory DatabaseHelper() {
    return _instance;
  }

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    // If the database is null, initialize it
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  // Enable foreign key support in SQLite
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Create the database tables
  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  // Handle schema migrations across database versions
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Ensure all tables exist for upgrades from earlier versions where tables were missing
      await _createTables(db);
    }
    if (oldVersion < 4) {
      await _migratePaymentsToSales(db);
    }
    if (oldVersion < 4) {
      // Bases antigas preservam os clientes; o novo campo começa como NULL.
      final columns = await db.rawQuery('PRAGMA table_info(customers)');
      if (!columns.any((column) => column['name'] == 'score')) {
        await db.execute('ALTER TABLE customers ADD COLUMN score INTEGER');
      }
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
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
        document_rg TEXT UNIQUE,
        score INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
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
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _migratePaymentsToSales(Database db) async {
    await db.execute('''
      CREATE TABLE payments_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      INSERT INTO payments_new (id, sale_id, method, amount, date)
      SELECT p.id,
             (
               SELECT s.id
               FROM sales s
               WHERE s.customer_id = p.customer_id
               ORDER BY s.date DESC, s.id DESC
               LIMIT 1
             ),
             p.method,
             p.amount,
             p.date
      FROM payments p
      WHERE EXISTS (
        SELECT 1 FROM sales s WHERE s.customer_id = p.customer_id
      )
    ''');
    await db.execute('DROP TABLE payments');
    await db.execute('ALTER TABLE payments_new RENAME TO payments');
  }
}

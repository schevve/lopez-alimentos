import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

import '../../../objectbox.g.dart';
import 'sqlite_migration.dart';

/// Mantém uma única instância do armazenamento local durante a execução.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  Future<Store>? _opening;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  /// O chamador é responsável por fechar stores fornecidos em testes.
  DatabaseHelper.withStore(Store store) : _opening = Future.value(store);

  Future<Store> get store => _opening ??= _open();

  Future<Store> _open() async {
    Store? opened;
    try {
      final directory = await getApplicationSupportDirectory();
      opened = await openStore(
        directory: path.join(directory.path, 'objectbox'),
      );
      final legacyPath = path.join(
        await sqlite.getDatabasesPath(),
        'app_database.db',
      );
      await SqliteMigration.importFile(opened, legacyPath);
      return opened;
    } catch (_) {
      opened?.close();
      _opening = null;
      rethrow;
    }
  }
}

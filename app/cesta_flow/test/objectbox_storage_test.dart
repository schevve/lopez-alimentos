import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_basket_input.dart';
import 'package:cesta_flow/core/data/local/model/migration_state.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/core/data/local/sqlite_migration.dart';
import 'package:cesta_flow/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqlite;

Customer customer({int? id, String cpf = '12345678901', String? rg}) =>
    Customer(
      id: id,
      uuid: 'customer-$cpf',
      name: 'Cliente de teste',
      dateOfBirth: DateTime(1990, 1, 1),
      phone: '45999999999',
      address: 'Rua de teste',
      addressNumber: '12',
      city: 'Cascavel',
      state: 'PR',
      documentCPF: cpf,
      documentRG: rg,
    );
Sale sale(int customerId, {int? id, DateTime? date}) => Sale(
  id: id,
  uuid: 'sale-${id ?? customerId}',
  customerId: customerId,
  price: 100,
  createdAt: date ?? DateTime(2026, 10, 1),
);
SaleBasketInput saleLine(Store store, {String uuid = 'basket-test'}) {
  store.box<Basket>().put(
    Basket(uuid: uuid, name: 'Cesta teste', price: 100),
  );
  return SaleBasketInput.catalog(basketUuid: uuid, quantity: 1);
}
Installment payment(int saleId, {int? id, double amount = 25}) => Installment(
  id: id,
  uuid: 'payment-${id ?? saleId}-$amount',
  saleId: saleId,
  amount: amount,
  paymentDate: DateTime(2026, 10, 2),
);

void main() {
  late Directory directory;
  late Store store;
  late CustomerRepository customers;
  late SaleRepository sales;
  late InstallmentRepository payments;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('cesta-objectbox-test-');
    store = Store(
      getObjectBoxModel(),
      directory: '${directory.path}/objectbox',
    );
    final helper = DatabaseHelper.withStore(store);
    customers = CustomerRepository(dbHelper: helper);
    sales = SaleRepository(dbHelper: helper);
    payments = InstallmentRepository(dbHelper: helper);
  });
  tearDown(() {
    store.close();
    directory.deleteSync(recursive: true);
  });

  test('CRUD, score nullable, documentos únicos e vários RGs nulos', () async {
    final id = await customers.registerCustomer(customer());
    final secondId = await customers.registerCustomer(
      customer(cpf: '98765432100'),
    );
    expect(secondId, greaterThan(id));
    expect((await customers.getCustomerById(id))!.score, isNull);
    await expectLater(
      customers.registerCustomer(customer()),
      throwsA(isA<UniqueViolationException>()),
    );
    final updated = (await customers.getCustomerById(id))!.copyWith(
      score: 940.0,
    );
    expect(await customers.updateCustomer(updated), 1);
    expect((await customers.getCustomerById(id))!.score, 940);
    await customers.updateCustomer(updated.copyWith(clearScore: true));
    expect((await customers.getCustomerById(id))!.score, isNull);
    expect(await customers.updateCustomer(customer(id: 999)), 0);
    expect(await customers.deleteCustomer(secondId), 1);
    expect(await customers.getCustomerById(secondId), isNull);
  });

  test('Vínculos, agregações, ordenação e exclusão em cascata', () async {
    final cid = await customers.registerCustomer(customer());
    final sid = await sales.registerSale(sale(cid), [saleLine(store)]);
    final laterId = await sales.registerSale(
      sale(cid, date: DateTime(2026, 10, 3)),
      [saleLine(store, uuid: 'basket-later')],
    );
    await expectLater(sales.registerSale(sale(999), []), throwsArgumentError);
    await expectLater(
      sales.registerSale(sale(999), [saleLine(store, uuid: 'basket-orphan')]),
      throwsStateError,
    );
    await expectLater(
      payments.registerInstallment(payment(999)),
      throwsStateError,
    );
    await payments.registerInstallment(payment(sid));
    await payments.registerInstallment(payment(sid, amount: 35));
    expect(await payments.paidAmountBySaleId(sid), 60);
    expect(await payments.paidTotalsBySaleIds([sid, laterId]), {sid: 60.0});
    expect(await payments.paidTotalsBySaleIds([]), isEmpty);
    expect((await sales.getSalesByCustomerId(cid)).first.id, laterId);
    expect((await sales.getLatestSales(limit: 1)).single.id, laterId);
    expect(await sales.getTotalSalesAmountSince(DateTime(2026, 10, 2)), 100);
    expect(await sales.getPendingCustomersCount(), 1);
    await sales.deleteSale(sid);
    expect(await payments.getAllInstallments(), isEmpty);
    await payments.registerInstallment(payment(laterId));
    await customers.deleteCustomer(cid);
    expect(await sales.getAllSales(), isEmpty);
    expect(await payments.getAllInstallments(), isEmpty);
  });

  test(
    'Migração preserva IDs, endereço antigo, nulos e é executada uma vez',
    () {
      final oldCustomer = customer(id: 12).toMap();
      oldCustomer['addres_number'] = oldCustomer.remove('address_number');
      void migrate() => SqliteMigration.importRows(
        store,
        customers: [oldCustomer],
        sales: [sale(12, id: 40).toMap()],
        payments: [payment(40, id: 70).toMap()],
      );
      migrate();
      expect(store.box<Customer>().get(12)!.addressNumber, '12');
      expect(store.box<Customer>().get(12)!.score, isNull);
      expect(store.box<Installment>().get(70)!.saleId, 40);
      final newId = store.box<Customer>().put(customer(cpf: '98765432100'));
      expect(newId, greaterThan(12));
      migrate();
      expect(store.box<Customer>().count(), 2);
      expect(store.box<Installment>().count(), 1);
      store.close();
      store = Store(
        getObjectBoxModel(),
        directory: '${directory.path}/objectbox',
      );
      expect(store.box<Sale>().get(40)!.customerId, 12);
      expect(store.box<MigrationState>().get(1), isNotNull);
    },
  );

  test(
    'Pagamento antigo ambíguo causa rollback total e permite nova tentativa',
    () {
      expect(
        () => SqliteMigration.importRows(
          store,
          customers: [customer(id: 1).toMap()],
          sales: [sale(1, id: 1).toMap()],
          payments: [
            {'id': 1, 'customer_id': 1, 'amount': 25},
          ],
        ),
        throwsStateError,
      );
      expect(store.box<Customer>().isEmpty(), isTrue);
      expect(store.box<Sale>().isEmpty(), isTrue);
      expect(store.box<MigrationState>().isEmpty(), isTrue);
      SqliteMigration.importRows(
        store,
        customers: [customer(id: 1).toMap()],
        sales: [sale(1, id: 1).toMap()],
        payments: [payment(1, id: 1).toMap()],
      );
      expect(store.box<Installment>().count(), 1);
    },
  );

  test('Rejeita órfãos e dados existentes sem sobrescrever o destino', () {
    expect(
      () => SqliteMigration.importRows(
        store,
        customers: [],
        sales: [sale(99, id: 1).toMap()],
        payments: [],
      ),
      throwsStateError,
    );
    store.box<Customer>().put(customer(id: 1));
    expect(
      () => SqliteMigration.importRows(
        store,
        customers: [customer(id: 1, cpf: '98765432100').toMap()],
        sales: [],
        payments: [],
      ),
      throwsStateError,
    );
    expect(store.box<Customer>().get(1)!.documentCPF, '12345678901');
  });

  test(
    'Importa arquivo SQLite real em leitura sem alterar versão ou conteúdo',
    () async {
      sqlite.sqfliteFfiInit();
      final file = '${directory.path}/app_database.db';
      final db = await sqlite.databaseFactoryFfi.openDatabase(file);
      await db.execute('PRAGMA user_version = 3');
      await db.execute(
        'CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, '
        'date_of_birth TEXT, phone TEXT, address TEXT, addres_number TEXT, city TEXT, '
        'state TEXT, document_cpf TEXT)',
      );
      await db.insert('customers', {
        'id': 7,
        'name': 'Cliente existente',
        'date_of_birth': '1990-01-01',
        'phone': '4500000000',
        'address': 'Rua Um',
        'addres_number': '20',
        'city': 'Cascavel',
        'state': 'PR',
        'document_cpf': '12345678901',
      });
      await db.close();
      final before = File(file).readAsBytesSync();
      await SqliteMigration.importFile(
        store,
        file,
        factory: sqlite.databaseFactoryFfi,
      );
      expect(store.box<Customer>().get(7)!.addressNumber, '20');
      expect(store.box<Customer>().get(7)!.score, isNull);
      expect(File(file).readAsBytesSync(), before);
    },
  );
}

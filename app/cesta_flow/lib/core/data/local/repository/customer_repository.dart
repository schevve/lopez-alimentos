import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/customer_model.dart';
import '../model/sale_model.dart';
import '../model/payment_model.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper;
  CustomerRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerCustomer(Customer value) async {
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      return db.box<Customer>().put(value);
    });
  }

  Future<Customer?> getCustomerById(int id) async =>
      (await _dbHelper.store).box<Customer>().get(id);
  Future<List<Customer>> getAllCustomers() async =>
      (await _dbHelper.store).box<Customer>().getAll();
  Future<int> updateCustomer(Customer value) async {
    if (value.id == null || value.id == 0) {
      throw ArgumentError('ID obrigatório para atualizar.');
    }
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Customer>().get(value.id!) == null) return 0;

      db.box<Customer>().put(value, mode: PutMode.update);
      return 1;
    });
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      final query = db.box<Sale>().query(Sale_.customerId.equals(id)).build();
      final sales = query.find();
      query.close();
      for (final sale in sales) {
        final payments = db
            .box<Payment>()
            .query(Payment_.saleId.equals(sale.id!))
            .build();
        payments.remove();
        payments.close();
        db.box<Sale>().remove(sale.id!);
      }
      return db.box<Customer>().remove(id) ? 1 : 0;
    });
  }
}

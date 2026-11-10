import '../../../../objectbox.g.dart';
import '../db_helper.dart';
import '../model/sale_model.dart';
import '../model/payment_model.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper;
  PaymentRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerPayment(Payment value) async {
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Sale>().get(value.saleId) == null) {
        throw StateError('Venda não encontrada.');
      }
      return db.box<Payment>().put(value);
    });
  }

  Future<Payment?> getPaymentById(int id) async =>
      (await _dbHelper.store).box<Payment>().get(id);
  Future<List<Payment>> getAllPayments() async =>
      (await _dbHelper.store).box<Payment>().getAll();
  Future<int> updatePayment(Payment value) async {
    if (value.id == null || value.id == 0) {
      throw ArgumentError('ID obrigatório para atualizar.');
    }
    final db = await _dbHelper.store;
    return db.runInTransaction(TxMode.write, () {
      if (db.box<Payment>().get(value.id!) == null) return 0;
      if (db.box<Sale>().get(value.saleId) == null) {
        throw StateError('Venda não encontrada.');
      }
      db.box<Payment>().put(value, mode: PutMode.update);
      return 1;
    });
  }

  Future<List<Payment>> getPaymentsBySaleId(int saleId) async {
    final db = await _dbHelper.store;
    final query = db
        .box<Payment>()
        .query(Payment_.saleId.equals(saleId))
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<double> getPaymentsBySaleIdAmount(int saleId) async =>
      (await getPaymentsBySaleId(saleId))
          .fold<double>(0, (sum, p) => sum + p.amount);

  Future<Map<int, double>> getPaymentTotalsBySaleIds(List<int> saleIds) async {
    if (saleIds.isEmpty) return {};
    final db = await _dbHelper.store;
    final query = db
        .box<Payment>()
        .query(Payment_.saleId.oneOf(saleIds))
        .build();
    try {
      final totals = <int, double>{};
      for (final p in query.find()) {
        totals.update(
          p.saleId,
          (sum) => sum + p.amount,
          ifAbsent: () => p.amount,
        );
      }
      return totals;
    } finally {
      query.close();
    }
  }

  Future<int> deletePayment(int id) async =>
      (await _dbHelper.store).box<Payment>().remove(id) ? 1 : 0;
}

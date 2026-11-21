import '../../../../objectbox.g.dart';
import '../../../domain/customer_score.dart';
import '../db_helper.dart';
import '../model/installment_model.dart';
import '../model/sale_model.dart';
import 'customer_repository.dart';

/// Lê compras e parcelas do cliente, calcula o score e grava score e bloqueio.
class CustomerScoreService {
  CustomerScoreService({DatabaseHelper? dbHelper, CustomerRepository? customers})
    : _dbHelper = dbHelper ?? DatabaseHelper(),
      _customers = customers ?? CustomerRepository(dbHelper: dbHelper);

  final DatabaseHelper _dbHelper;
  final CustomerRepository _customers;

  Future<void> recalculate(int customerId, {DateTime? today}) async {
    final customer = await _customers.getCustomerById(customerId);
    if (customer == null) return;

    final db = await _dbHelper.store;
    final sales = _salesOf(db, customerId);
    final prices = <double>[];
    final counts = <int>[];
    final timings = <InstallmentTiming>[];
    for (final sale in sales) {
      prices.add(sale.price);
      final installments = sale.id == null
          ? const <Installment>[]
          : _installmentsOf(db, sale.id!);
      if (installments.isEmpty) {
        counts.add(sale.installments);
        continue;
      }
      counts.add(installments.length);
      for (final installment in installments) {
        timings.add(
          InstallmentTiming(
            dueDate: installment.dueDate,
            paymentDate: installment.paymentDate,
          ),
        );
      }
    }

    final score = calculateCustomerScore(
      salePrices: prices,
      installmentCounts: counts,
      timings: timings,
      today: today,
    );
    final blocked = blockedAfterScore(
      alreadyBlocked: customer.isBlocked,
      score: score,
    );
    if (customer.score == score && customer.isBlocked == blocked) return;

    await _customers.updateCustomer(
      customer.copyWith(
        score: score,
        clearScore: score == null,
        isBlocked: blocked,
      ),
    );
  }

  List<Sale> _salesOf(Store db, int customerId) {
    final query = db
        .box<Sale>()
        .query(
          Sale_.customerId
              .equals(customerId)
              .and(Sale_.isDeleted.equals(false)),
        )
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  List<Installment> _installmentsOf(Store db, int saleId) {
    final query = db
        .box<Installment>()
        .query(
          Installment_.saleId
              .equals(saleId)
              .and(Installment_.isDeleted.equals(false)),
        )
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}

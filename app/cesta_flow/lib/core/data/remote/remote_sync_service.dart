import '../local/db_helper.dart';
import '../local/repository/basket_repository.dart';
import '../local/repository/customer_repository.dart';
import '../local/repository/installment_repository.dart';
import '../local/repository/payment_repository.dart';
import '../local/repository/sale_repository.dart';
import 'sync_preferences.dart';

class RemoteSyncService {
  RemoteSyncService({
    DatabaseHelper? dbHelper,
    SyncPreferences? syncPreferences,
    CustomerRepository? customerRepository,
    BasketRepository? basketRepository,
    SaleRepository? saleRepository,
    InstallmentRepository? installmentRepository,
    PaymentRepository? paymentRepository,
  }) : _syncPreferences = syncPreferences ?? SyncPreferences(),
       _customerRepository = customerRepository ??
           CustomerRepository(dbHelper: dbHelper),
       _basketRepository = basketRepository ??
           BasketRepository(dbHelper: dbHelper),
       _saleRepository = saleRepository ?? SaleRepository(dbHelper: dbHelper),
       _installmentRepository = installmentRepository ??
           InstallmentRepository(dbHelper: dbHelper),
       _paymentRepository = paymentRepository ??
           PaymentRepository(dbHelper: dbHelper);

  final SyncPreferences _syncPreferences;
  final CustomerRepository _customerRepository;
  final BasketRepository _basketRepository;
  final SaleRepository _saleRepository;
  final InstallmentRepository _installmentRepository;
  final PaymentRepository _paymentRepository;

  /// Envia alterações locais pendentes e depois busca atualizações remotas.
  Future<void> synchronize() async {
    final pullSince =
        await _syncPreferences.getLastPushAt() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    await _push();
    await _pull(pullSince);
  }

  Future<void> _push() async {
    await _customerRepository.pushUnsynced();
    await _basketRepository.pushUnsyncedBaskets();
    await _saleRepository.pushUnsynced();
    await _basketRepository.pushUnsyncedSaleBaskets();
    await _installmentRepository.pushUnsynced();
    await _paymentRepository.pushUnsynced();
    await _syncPreferences.setLastPushAt(DateTime.now().toUtc());
  }

  Future<void> _pull(DateTime since) async {
    await _customerRepository.pullSince(since);
    await _basketRepository.pullBasketsSince(since);
    await _saleRepository.pullSince(since);
    await _basketRepository.pullSaleBasketsSince(since);
    await _installmentRepository.pullSince(since);
    await _paymentRepository.pullSince(since);
  }
}

import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/payment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/payment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';

Customer customer({int? id, String cpf = '12345678901', String? rg}) =>
    Customer(
      id: id,
      name: 'Cliente de teste',
      dateOfBirth: DateTime(1990, 1, 1),
      phone: '45999999999',
      address: 'Rua de teste',
      adressNumber: '12',
      city: 'Cascavel',
      state: 'PR',
      documentCPF: cpf,
      documentRG: rg,
    );
Sale sale(int customerId, {int? id, DateTime? date}) => Sale(
  id: id,
  customerId: customerId,
  productName: 'Cesta',
  price: 50,
  quantity: 2,
  date: date ?? DateTime(2026, 10, 1),
  description: '',
);
Payment payment(int saleId, {int? id, double amount = 25}) => Payment(
  id: id,
  saleId: saleId,
  method: 'Pix',
  amount: amount,
  date: DateTime(2026, 10, 2),
);

void main() {
  late Directory directory;
  late Store store;
  late CustomerRepository customers;
  late SaleRepository sales;
  late PaymentRepository payments;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('cesta-objectbox-test-');
    store = Store(
      getObjectBoxModel(),
      directory: '${directory.path}/objectbox',
    );
    final helper = DatabaseHelper.withStore(store);
    customers = CustomerRepository(dbHelper: helper);
    sales = SaleRepository(dbHelper: helper);
    payments = PaymentRepository(dbHelper: helper);
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
    final updated = (await customers.getCustomerById(id))!.copyWith(score: 940);
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
    final sid = await sales.registerSale(sale(cid));
    final laterId = await sales.registerSale(
      sale(cid, date: DateTime(2026, 10, 3)),
    );
    await expectLater(sales.registerSale(sale(999)), throwsStateError);
    await expectLater(payments.registerPayment(payment(999)), throwsStateError);
    await payments.registerPayment(payment(sid));
    await payments.registerPayment(payment(sid, amount: 35));
    expect(await payments.getPaymentsBySaleIdAmount(sid), 60);
    expect(await payments.getPaymentTotalsBySaleIds([sid, laterId]), {
      sid: 60.0,
    });
    expect(await payments.getPaymentTotalsBySaleIds([]), isEmpty);
    expect((await sales.getSalesByCustomerId(cid)).first.id, laterId);
    expect((await sales.getLatestSales(limit: 1)).single.id, laterId);
    expect(await sales.getTotalSalesAmountSince(DateTime(2026, 10, 2)), 100);
    expect(await sales.getPendingCustomersCount(), 1);
    await sales.deleteSale(sid);
    expect(await payments.getAllPayments(), isEmpty);
    await payments.registerPayment(payment(laterId));
    await customers.deleteCustomer(cid);
    expect(await sales.getAllSales(), isEmpty);
    expect(await payments.getAllPayments(), isEmpty);
  });

  test('Preserva clientes, vendas e pagamentos ao reabrir o banco', () async {
    final customerId = await customers.registerCustomer(customer());
    final saleId = await sales.registerSale(sale(customerId));
    final paymentId = await payments.registerPayment(payment(saleId));
    store.close();
    store = Store(
      getObjectBoxModel(),
      directory: '${directory.path}/objectbox',
    );
    expect(store.box<Customer>().get(customerId)!.adressNumber, '12');
    expect(store.box<Customer>().get(customerId)!.score, isNull);
    expect(store.box<Sale>().get(saleId)!.customerId, customerId);
    expect(store.box<Payment>().get(paymentId)!.saleId, saleId);
    expect(store.box<Payment>().get(paymentId)!.amount, 25);
  });
}

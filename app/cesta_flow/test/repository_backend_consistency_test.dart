import 'dart:io';

import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_basket_input.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/basket_repository.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/core/data/local/sync_entity_lookup.dart';
import 'package:cesta_flow/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const _supabaseUrl = 'https://vzpomvpwbqaesfezxehf.supabase.co';
const _publishableKey = 'sb_publishable_Y5sHcuLfegaSCvK_c5RUFg_-ecEu179';

void main() {
  test(
    'register, update e delete ficam consistentes com o Supabase',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = null;
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _publishableKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: const EmptyLocalStorage(),
          pkceAsyncStorage: _MemoryAsyncStorage(),
        ),
      );

      final directory = Directory.systemTemp.createTempSync(
        'cesta-backend-consistency-',
      );
      final store = Store(
        getObjectBoxModel(),
        directory: '${directory.path}/objectbox',
      );
      final helper = DatabaseHelper.withStore(store);
      final customers = CustomerRepository(dbHelper: helper);
      final baskets = BasketRepository(dbHelper: helper);
      final sales = SaleRepository(dbHelper: helper);
      final installments = InstallmentRepository(dbHelper: helper);
      final client = Supabase.instance.client;
      final email = Platform.environment['SUPABASE_TEST_EMAIL'];
      final password = Platform.environment['SUPABASE_TEST_PASSWORD'];
      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        fail(
          'Defina SUPABASE_TEST_EMAIL e SUPABASE_TEST_PASSWORD para autenticar.',
        );
      }
      await client.auth.signInWithPassword(email: email, password: password);

      final stamp = DateTime.now().microsecondsSinceEpoch;
      final customerUuid = const Uuid().v4();
      final basketUuid = const Uuid().v4();
      final saleUuid = const Uuid().v4();
      final installmentUuid = const Uuid().v4();
      final cpf = (stamp % 100000000000).toString().padLeft(11, '0');
      final createdAt = DateTime.utc(2026, 11, 19, 12);

      Future<Map<String, dynamic>?> remote(
        String table,
        String column,
        String value,
      ) async {
        final rows = await client.from(table).select().eq(column, value);
        if (rows.isEmpty) return null;
        return Map<String, dynamic>.from(rows.first as Map);
      }

      Future<void> recover() async {
        await customers.pushUnsynced();
        await baskets.pushUnsyncedBaskets();
        await sales.pushUnsynced();
        await installments.pushUnsynced();
        await baskets.pushUnsyncedSaleBaskets();
      }

      void expectSynced(bool? isSynced, String label) {
        if (isSynced != true) {
          throw StateError('$label local ainda não está sincronizado.');
        }
      }

      final steps = <_Step>[
        _Step(
          'CustomerRepository.registerCustomer',
          () => customers.registerCustomer(
            Customer(
              uuid: customerUuid,
              name: 'Consistencia Backend',
              dateOfBirth: DateTime.utc(1990, 1, 1),
              phone: '45999990000',
              address: 'Rua do Teste',
              addressNumber: '10',
              city: 'Toledo',
              state: 'PR',
              documentCPF: cpf,
              createdAt: createdAt,
            ),
          ),
          () async {
            final local = findCustomerByUuid(store, customerUuid);
            expectSynced(local?.isSynced, 'cliente');
            final row = await remote('customers', 'id', customerUuid);
            if (row == null) throw StateError('cliente ausente no backend');
            if (row['name'] != 'Consistencia Backend') {
              throw StateError('nome remoto ${row['name']}');
            }
            if (row['cpf'] != cpf) throw StateError('cpf remoto ${row['cpf']}');
            if (row['deleted_at'] != null) {
              throw StateError('cliente remoto já excluído');
            }
          },
        ),
        _Step(
          'CustomerRepository.updateCustomer',
          () async {
            final local = findCustomerByUuid(store, customerUuid)!;
            await customers.updateCustomer(
              local.copyWith(name: 'Consistencia Atualizada', updatedAt: createdAt),
            );
          },
          () async {
            final local = findCustomerByUuid(store, customerUuid);
            expectSynced(local?.isSynced, 'cliente atualizado');
            final row = await remote('customers', 'id', customerUuid);
            if (row?['name'] != 'Consistencia Atualizada') {
              throw StateError('nome remoto após update: ${row?['name']}');
            }
          },
        ),
        _Step(
          'BasketRepository.registerBasket',
          () => baskets.registerBasket(
            Basket(
              uuid: basketUuid,
              name: 'Cesta consistencia',
              price: 80,
              createdAt: createdAt,
            ),
          ),
          () async {
            final local = findBasketByUuid(store, basketUuid);
            expectSynced(local?.isSynced, 'cesta');
            final row = await remote('baskets', 'id', basketUuid);
            if (row == null) throw StateError('cesta ausente no backend');
            if (row['name'] != 'Cesta consistencia') {
              throw StateError('nome da cesta ${row['name']}');
            }
            if ((row['price'] as num?)?.toDouble() != 80) {
              throw StateError('preço remoto ${row['price']}');
            }
          },
        ),
        _Step(
          'SaleRepository.registerSale',
          () async {
            final customer = findCustomerByUuid(store, customerUuid)!;
            await sales.registerSale(
              Sale(
                uuid: saleUuid,
                customerId: customer.id!,
                customerUuid: customer.uuid,
                price: 80,
                installments: 1,
                createdAt: createdAt,
              ),
              [SaleBasketInput.catalog(basketUuid: basketUuid, quantity: 2)],
            );
          },
          () async {
            final local = findSaleByUuid(store, saleUuid);
            expectSynced(local?.isSynced, 'venda');
            final row = await remote('sales', 'id', saleUuid);
            if (row == null) throw StateError('venda ausente no backend');
            if (row['customer_id'] != customerUuid) {
              throw StateError('customer_id remoto ${row['customer_id']}');
            }
            if ((row['price'] as num?)?.toDouble() != 80) {
              throw StateError('preço da venda ${row['price']}');
            }
            final links = await client
                .from('sale_baskets')
                .select()
                .eq('sale_id', saleUuid)
                .eq('basket_id', basketUuid);
            if (links.isEmpty) throw StateError('vínculo da cesta ausente');
            final link = Map<String, dynamic>.from(links.first as Map);
            if ((link['quantity'] as num?)?.toInt() != 2) {
              throw StateError('quantidade remota ${link['quantity']}');
            }
            final localLink = findSaleBasketByUuids(
              store,
              saleUuid: saleUuid,
              basketUuid: basketUuid,
            );
            expectSynced(localLink?.isSynced, 'vínculo da cesta');
          },
        ),
        _Step(
          'SaleRepository.updateSale',
          () async {
            final local = findSaleByUuid(store, saleUuid)!;
            await sales.updateSale(
              local.copyWith(price: 90, updatedAt: createdAt),
            );
          },
          () async {
            final local = findSaleByUuid(store, saleUuid);
            expectSynced(local?.isSynced, 'venda atualizada');
            final row = await remote('sales', 'id', saleUuid);
            if ((row?['price'] as num?)?.toDouble() != 90) {
              throw StateError('preço remoto após update: ${row?['price']}');
            }
          },
        ),
        _Step(
          'InstallmentRepository.createInstallment',
          () async {
            final sale = findSaleByUuid(store, saleUuid)!;
            await installments.createInstallment(
              Installment(
                uuid: installmentUuid,
                saleId: sale.id!,
                saleUuid: sale.uuid,
                expectedAmount: 90,
                dueDate: DateTime.utc(2026, 12, 1),
                createdAt: createdAt,
              ),
            );
          },
          () async {
            final local = findInstallmentByUuid(store, installmentUuid);
            expectSynced(local?.isSynced, 'parcela');
            final row = await remote('installments', 'id', installmentUuid);
            if (row == null) throw StateError('parcela ausente no backend');
            if (row['sale_id'] != saleUuid) {
              throw StateError('sale_id remoto ${row['sale_id']}');
            }
            if ((row['expected_amount'] as num?)?.toDouble() != 90) {
              throw StateError('valor esperado ${row['expected_amount']}');
            }
          },
        ),
        _Step(
          'InstallmentRepository.updateInstallment',
          () async {
            final local = findInstallmentByUuid(store, installmentUuid)!;
            await installments.updateInstallment(
              local.copyWith(expectedAmount: 90, paymentMethod: 'pix'),
            );
          },
          () async {
            final local = findInstallmentByUuid(store, installmentUuid);
            expectSynced(local?.isSynced, 'parcela atualizada');
            final row = await remote('installments', 'id', installmentUuid);
            if (row?['payment_method'] != 'pix') {
              throw StateError('método remoto ${row?['payment_method']}');
            }
          },
        ),
        _Step(
          'InstallmentRepository.registerPayment',
          () async {
            final sale = findSaleByUuid(store, saleUuid)!;
            await installments.registerPayment(
              saleId: sale.id!,
              amount: 30,
              paymentMethod: 'dinheiro',
              paymentDate: createdAt,
            );
          },
          () async {
            final local = findInstallmentByUuid(store, installmentUuid);
            final sale = findSaleByUuid(store, saleUuid);
            expectSynced(local?.isSynced, 'parcela paga');
            expectSynced(sale?.isSynced, 'venda após pagamento');
            if (local?.paidAmount != 30) {
              throw StateError('pago local ${local?.paidAmount}');
            }
            final row = await remote('installments', 'id', installmentUuid);
            if ((row?['paid_amount'] as num?)?.toDouble() != 30) {
              throw StateError('pago remoto ${row?['paid_amount']}');
            }
            final saleRow = await remote('sales', 'id', saleUuid);
            if ((saleRow?['amount_paid'] as num?)?.toDouble() != 30) {
              throw StateError('amount_paid remoto ${saleRow?['amount_paid']}');
            }
          },
        ),
        _Step(
          'InstallmentRepository.deleteInstallment',
          () async {
            final local = findInstallmentByUuid(store, installmentUuid)!;
            await installments.deleteInstallment(local.id!);
          },
          () async {
            final local = findInstallmentByUuid(store, installmentUuid);
            expectSynced(local?.isSynced, 'parcela excluída');
            if (local?.isDeleted != true) {
              throw StateError('parcela local não foi excluída');
            }
            final row = await remote('installments', 'id', installmentUuid);
            if (row?['deleted_at'] == null) {
              throw StateError('deleted_at remoto da parcela: ${row?['deleted_at']}');
            }
          },
        ),
        _Step(
          'SaleRepository.deleteSale',
          () async {
            final local = findSaleByUuid(store, saleUuid)!;
            await sales.deleteSale(local.id!);
          },
          () async {
            final local = findSaleByUuid(store, saleUuid);
            final basket = findBasketByUuid(store, basketUuid);
            expectSynced(local?.isSynced, 'venda excluída');
            expectSynced(basket?.isSynced, 'cesta excluída com a venda');
            if (local?.isDeleted != true || basket?.isDeleted != true) {
              throw StateError('exclusão local da venda incompleta');
            }
            final saleRow = await remote('sales', 'id', saleUuid);
            final basketRow = await remote('baskets', 'id', basketUuid);
            if (saleRow?['deleted_at'] == null) {
              throw StateError('deleted_at remoto da venda: ${saleRow?['deleted_at']}');
            }
            if (basketRow?['deleted_at'] == null) {
              throw StateError('deleted_at remoto da cesta: ${basketRow?['deleted_at']}');
            }
            final links = await client
                .from('sale_baskets')
                .select()
                .eq('sale_id', saleUuid)
                .eq('basket_id', basketUuid);
            if (links.isEmpty ||
                Map<String, dynamic>.from(links.first as Map)['deleted_at'] ==
                    null) {
              throw StateError('vínculo remoto não excluído');
            }
          },
        ),
        _Step(
          'CustomerRepository.deleteCustomer',
          () async {
            final local = findCustomerByUuid(store, customerUuid)!;
            await customers.deleteCustomer(local.id!);
          },
          () async {
            final local = findCustomerByUuid(store, customerUuid);
            expectSynced(local?.isSynced, 'cliente excluído');
            if (local?.isDeleted != true) {
              throw StateError('cliente local não foi excluído');
            }
            final row = await remote('customers', 'id', customerUuid);
            if (row?['deleted_at'] == null) {
              throw StateError('deleted_at remoto do cliente: ${row?['deleted_at']}');
            }
          },
        ),
      ];

      final errors = <String, Object>{};
      try {
        for (var attempt = 1; attempt <= 8; attempt++) {
          var blocked = false;
          for (final step in steps) {
            if (step.consistent) continue;
            if (blocked) continue;
            try {
              if (step.attempts == 0) {
                await step.run();
              } else {
                await recover();
              }
              await step.verify();
              step.consistent = true;
              errors.remove(step.name);
            } catch (error) {
              errors.putIfAbsent(step.name, () => error);
              blocked = true;
            } finally {
              step.attempts++;
            }
          }
          if (steps.every((step) => step.consistent)) break;
          await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
        }
        if (errors.isNotEmpty) {
          fail(
            errors.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n'),
          );
        }
      } finally {
        store.close();
        directory.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}

class _Step {
  _Step(this.name, this.run, this.verify);

  final String name;
  final Future<void> Function() run;
  final Future<void> Function() verify;
  int attempts = 0;
  bool consistent = false;
}

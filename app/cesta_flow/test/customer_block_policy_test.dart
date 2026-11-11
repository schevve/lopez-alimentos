import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/domain/customer_block_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Customer customer({bool authorized = false, bool? manualBlockOverride}) {
    return Customer(
      name: 'Cliente',
      dateOfBirth: DateTime(1970),
      phone: '45999990000',
      address: 'Rua Um',
      adress_number: '10',
      city: 'Toledo',
      state: 'PR',
      documentCPF: '12345678901',
      authorized: authorized,
      manualBlockOverride: manualBlockOverride,
    );
  }

  test('Menos de quatro parcelas abertas não bloqueia automaticamente', () {
    expect(
      isCustomerBlocked(customer: customer(), openInstallmentCount: 3),
      isFalse,
    );
  });

  test('Quatro parcelas abertas bloqueiam automaticamente', () {
    expect(
      isCustomerBlocked(customer: customer(), openInstallmentCount: 4),
      isTrue,
    );
  });

  test('Cliente autorizado não sofre bloqueio automático', () {
    expect(
      isCustomerBlocked(
        customer: customer(authorized: true),
        openInstallmentCount: 4,
      ),
      isFalse,
    );
  });

  test('Bloqueio manual prevalece mesmo para cliente autorizado', () {
    expect(
      isCustomerBlocked(
        customer: customer(authorized: true, manualBlockOverride: true),
        openInstallmentCount: 0,
      ),
      isTrue,
    );
  });

  test('Desbloqueio manual prevalece sobre bloqueio automático', () {
    expect(
      isCustomerBlocked(
        customer: customer(manualBlockOverride: false),
        openInstallmentCount: 4,
      ),
      isFalse,
    );
  });

  test('Override manual de bloqueio bloqueia abaixo do limite', () {
    expect(
      isCustomerBlocked(
        customer: customer(manualBlockOverride: true),
        openInstallmentCount: 0,
      ),
      isTrue,
    );
  });

  test('Rejeita quantidade negativa de parcelas abertas', () {
    expect(
      () => isCustomerBlocked(customer: customer(), openInstallmentCount: -1),
      throwsArgumentError,
    );
  });
}

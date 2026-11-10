import 'package:cesta_flow/core/domain/payment_allocation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final saleDate = DateTime(2026, 11, 10);

  InstallmentBalance installment({
    required int id,
    required int number,
    required int amount,
    int paid = 0,
  }) {
    return InstallmentBalance(
      id: id,
      number: number,
      amountCents: amount,
      paidCents: paid,
    );
  }

  test('Pagamento parcial é vinculado à próxima parcela em aberto', () {
    final plan = createPaymentAllocationPlan(
      saleId: 5,
      paymentCents: 500,
      saleBalanceCents: 2000,
      installments: [installment(id: 1, number: 1, amount: 1000)],
      saleDate: saleDate,
    );

    expect(plan.allocations, hasLength(1));
    expect(plan.allocations.single.installmentId, 1);
    expect(plan.allocations.single.amountCents, 500);
    expect(plan.newInstallment, isNull);
  });

  test('Divide o pagamento em parcelas pela ordem', () {
    final plan = createPaymentAllocationPlan(
      saleId: 5,
      paymentCents: 2500,
      saleBalanceCents: 3000,
      installments: [
        installment(id: 2, number: 2, amount: 2000),
        installment(id: 1, number: 1, amount: 1000),
      ],
      saleDate: saleDate,
    );

    expect(
      plan.allocations.map(
        (allocation) => (allocation.installmentId, allocation.amountCents),
      ),
      [(1, 1000), (2, 1500)],
    );
  });

  test('Recusa pagamento acima do saldo total', () {
    expect(
      () => createPaymentAllocationPlan(
        saleId: 5,
        paymentCents: 1001,
        saleBalanceCents: 1000,
        installments: [installment(id: 1, number: 1, amount: 1000)],
        saleDate: saleDate,
      ),
      throwsA(isA<PaymentExceedsBalanceException>()),
    );
  });

  test('Cria parcela extra com saldo e aplica pagamento excedente a ela', () {
    final plan = createPaymentAllocationPlan(
      saleId: 5,
      paymentCents: 8000,
      saleBalanceCents: 10000,
      installments: [installment(id: 1, number: 1, amount: 6000)],
      saleDate: saleDate,
    );

    expect(plan.newInstallment?.number, 2);
    expect(plan.newInstallment?.amount, 40);
    expect(plan.newInstallment?.dueDate, DateTime(2027, 1, 10));
    expect(plan.allocations, hasLength(2));
    expect(plan.allocations.last.isForNewInstallment, isTrue);
    expect(plan.allocations.last.amountCents, 2000);
  });

  test('Distribui centavos sem perder valor', () {
    final plan = createPaymentAllocationPlan(
      saleId: 5,
      paymentCents: 2,
      saleBalanceCents: 3,
      installments: [
        installment(id: 1, number: 1, amount: 1),
        installment(id: 2, number: 2, amount: 2),
      ],
      saleDate: saleDate,
    );

    expect(plan.allocations.map((allocation) => allocation.amountCents), [
      1,
      1,
    ]);
  });

  test('Quitação completa não cria parcela adicional', () {
    final plan = createPaymentAllocationPlan(
      saleId: 5,
      paymentCents: 10000,
      saleBalanceCents: 10000,
      installments: [installment(id: 1, number: 1, amount: 10000)],
      saleDate: saleDate,
    );

    expect(plan.newInstallment, isNull);
    expect(
      plan.allocations.fold<int>(
        0,
        (total, allocation) => total + allocation.amountCents,
      ),
      10000,
    );
  });

  test('Parcela concluída cria extra com o saldo sem exceder a venda', () {
    final plan = createPaymentAllocationPlan(
      saleId: 5,
      paymentCents: 6000,
      saleBalanceCents: 10000,
      installments: [installment(id: 1, number: 1, amount: 6000)],
      saleDate: saleDate,
    );

    expect(plan.allocations.single.amountCents, 6000);
    expect(plan.newInstallment?.amount, 40);
  });
}

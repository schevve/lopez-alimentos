import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/domain/installment_schedule.dart';

class InstallmentBalance {
  const InstallmentBalance({
    required this.id,
    required this.number,
    required this.amountCents,
    required this.paidCents,
  });

  final int id;
  final int number;
  final int amountCents;
  final int paidCents;
}

class PaymentAllocation {
  const PaymentAllocation({
    required this.installmentNumber,
    required this.amountCents,
    this.installmentId,
    this.isForNewInstallment = false,
  });

  final int installmentNumber;
  final int amountCents;
  final int? installmentId;
  final bool isForNewInstallment;
}

class PaymentAllocationPlan {
  const PaymentAllocationPlan({required this.allocations, this.newInstallment});

  final List<PaymentAllocation> allocations;
  final Installment? newInstallment;
}

class PaymentExceedsBalanceException implements Exception {
  const PaymentExceedsBalanceException({
    required this.paymentCents,
    required this.balanceCents,
  });

  final int paymentCents;
  final int balanceCents;

  @override
  String toString() =>
      'O valor informado excede o saldo da venda de '
      'R\$ ${(balanceCents / 100).toStringAsFixed(2)}.';
}

PaymentAllocationPlan createPaymentAllocationPlan({
  required int saleId,
  required int paymentCents,
  required int saleBalanceCents,
  required List<InstallmentBalance> installments,
  required DateTime saleDate,
}) {
  if (paymentCents <= 0) {
    throw ArgumentError.value(
      paymentCents,
      'paymentCents',
      'Must be greater than zero.',
    );
  }
  if (saleBalanceCents < 0) {
    throw ArgumentError.value(
      saleBalanceCents,
      'saleBalanceCents',
      'Cannot be negative.',
    );
  }
  if (paymentCents > saleBalanceCents) {
    throw PaymentExceedsBalanceException(
      paymentCents: paymentCents,
      balanceCents: saleBalanceCents,
    );
  }

  final orderedInstallments = [...installments]
    ..sort((a, b) {
      final byNumber = a.number.compareTo(b.number);
      return byNumber != 0 ? byNumber : a.id.compareTo(b.id);
    });
  final allocations = <PaymentAllocation>[];
  var remainingPayment = paymentCents;
  var allocatedCents = 0;
  var nextNumber = 1;

  for (final installment in orderedInstallments) {
    if (installment.number >= nextNumber) {
      nextNumber = installment.number + 1;
    }
    final openCents = installment.amountCents - installment.paidCents;
    if (openCents <= 0 || remainingPayment == 0) continue;

    final appliedCents = remainingPayment < openCents
        ? remainingPayment
        : openCents;
    allocations.add(
      PaymentAllocation(
        installmentId: installment.id,
        installmentNumber: installment.number,
        amountCents: appliedCents,
      ),
    );
    remainingPayment -= appliedCents;
    allocatedCents += appliedCents;
  }

  final allInstallmentsSettled = orderedInstallments.every((installment) {
    final appliedToInstallment = allocations
        .where((allocation) => allocation.installmentId == installment.id)
        .fold<int>(0, (total, allocation) => total + allocation.amountCents);
    return installment.paidCents + appliedToInstallment >=
        installment.amountCents;
  });
  Installment? newInstallment;
  if (allInstallmentsSettled && saleBalanceCents - allocatedCents > 0) {
    final remainingSaleBalance = saleBalanceCents - allocatedCents;
    newInstallment = Installment(
      saleId: saleId,
      number: nextNumber,
      amount: remainingSaleBalance / 100,
      dueDate: monthlyInstallmentDueDate(saleDate, nextNumber),
    );
    final appliedCents = remainingPayment < remainingSaleBalance
        ? remainingPayment
        : remainingSaleBalance;
    if (appliedCents > 0) {
      allocations.add(
        PaymentAllocation(
          installmentNumber: nextNumber,
          amountCents: appliedCents,
          isForNewInstallment: true,
        ),
      );
    }
  }

  return PaymentAllocationPlan(
    allocations: List.unmodifiable(allocations),
    newInstallment: newInstallment,
  );
}

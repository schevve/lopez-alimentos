class Installment {
  final int? id;
  final int saleId;
  final int number;
  final double amount;
  final DateTime? dueDate;
  final double paidAmount;
  final DateTime? paidAt;
  final String? paymentMethod;

  const Installment({
    this.id,
    required this.saleId,
    required this.number,
    required this.amount,
    this.dueDate,
    this.paidAmount = 0,
    this.paidAt,
    this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sale_id': saleId,
      'number': number,
      'amount': amount,
      'due_date': dueDate?.toIso8601String(),
      'paid_amount': paidAmount,
      'paid_at': paidAt?.toIso8601String(),
      'payment_method': paymentMethod,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    final dueDate = map['due_date'] as String?;
    final paidAt = map['paid_at'] as String?;
    return Installment(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      number: map['number'] as int,
      amount: (map['amount'] as num).toDouble(),
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      paidAt: paidAt == null ? null : DateTime.parse(paidAt),
      paymentMethod: map['payment_method'] as String?,
    );
  }

  Installment copyWith({
    int? id,
    int? saleId,
    int? number,
    double? amount,
    DateTime? dueDate,
    double? paidAmount,
    DateTime? paidAt,
    String? paymentMethod,
    bool clearDueDate = false,
    bool clearPaidAt = false,
    bool clearPaymentMethod = false,
  }) {
    return Installment(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      number: number ?? this.number,
      amount: amount ?? this.amount,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      paidAmount: paidAmount ?? this.paidAmount,
      paidAt: clearPaidAt ? null : paidAt ?? this.paidAt,
      paymentMethod: clearPaymentMethod
          ? null
          : paymentMethod ?? this.paymentMethod,
    );
  }
}

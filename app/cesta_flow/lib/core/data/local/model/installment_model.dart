class Installment {
  final int? id;
  final int saleId;
  final int number;
  final double amount;
  final DateTime? dueDate;

  const Installment({
    this.id,
    required this.saleId,
    required this.number,
    required this.amount,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sale_id': saleId,
      'number': number,
      'amount': amount,
      'due_date': dueDate?.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    final dueDate = map['due_date'] as String?;
    return Installment(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      number: map['number'] as int,
      amount: (map['amount'] as num).toDouble(),
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
    );
  }

  Installment copyWith({
    int? id,
    int? saleId,
    int? number,
    double? amount,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Installment(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      number: number ?? this.number,
      amount: amount ?? this.amount,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
    );
  }
}

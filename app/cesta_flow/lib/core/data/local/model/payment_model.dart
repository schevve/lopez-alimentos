class Payment {
  final int? id;
  final int saleId;
  final String method;
  final double amount;
  final DateTime date;

  Payment({
    this.id,
    required this.saleId,
    required this.method,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sale_id': saleId,
      'method': method,
      'amount': amount,
      'date': date.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      method: map['method'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }

  Payment copyWith({
    int? id,
    int? saleId,
    String? method,
    double? amount,
    DateTime? date,
  }) {
    return Payment(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'Payment{id: $id, saleId: $saleId, method: $method, amount: $amount, date: $date}';
  }
}

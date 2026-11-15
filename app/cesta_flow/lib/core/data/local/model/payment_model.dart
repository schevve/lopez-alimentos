import 'package:objectbox/objectbox.dart';

@Entity()
class Payment {
  @Id(assignable: true)
  int? id;
  String uuid;
  @Index()
  final int saleId;
  final String method;
  final double amount;
  @Property(type: PropertyType.dateNano)
  final DateTime date;
  final bool isBlocked;
  final bool isDeleted;
  final bool isSynced;

  Payment({
    this.id,
    required this.uuid,
    required this.saleId,
    required this.method,
    required this.amount,
    required this.date,
    this.isBlocked = false,
    this.isDeleted = false,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'sale_id': saleId,
      'method': method,
      'amount': amount,
      'date': date.toIso8601String(),
      'is_blocked': isBlocked,
      'is_deleted': isDeleted,
      'is_synced': isSynced,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      saleId: map['sale_id'] as int,
      method: map['method'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      isBlocked: map['is_blocked'] as bool? ?? false,
      isDeleted: map['is_deleted'] as bool? ?? false,
      isSynced: map['is_synced'] as bool? ?? false,
    );
  }

  Payment copyWith({
    int? id,
    String? uuid,
    int? saleId,
    String? method,
    double? amount,
    DateTime? date,
    bool? isBlocked,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return Payment(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      saleId: saleId ?? this.saleId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isBlocked: isBlocked ?? this.isBlocked,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'Payment{id: $id, uuid: $uuid, saleId: $saleId, method: $method, amount: $amount, date: $date, isBlocked: $isBlocked, isDeleted: $isDeleted, isSynced: $isSynced}';
  }
}

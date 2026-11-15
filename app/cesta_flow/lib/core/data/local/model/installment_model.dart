import 'package:objectbox/objectbox.dart';

@Entity()
class Installment {
  @Id(assignable: true)
  int? id;
  String uuid;
  @Index()
  final int saleId;
  final String saleUuid;
  final double amount;
  @Property(type: PropertyType.dateNano)
  final DateTime? dueDate;
  @Property(type: PropertyType.dateNano)
  final DateTime? paymentDate;
  @Property(type: PropertyType.dateNano)
  final DateTime createdAt;
  @Property(type: PropertyType.dateNano)
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isSynced;

  Installment({
    this.id,
    required this.uuid,
    required this.saleId,
    this.saleUuid = '',
    required this.amount,
    this.dueDate,
    this.paymentDate,
    DateTime? createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPaid => paymentDate != null;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'sale_id': saleId,
      'sale_uuid': saleUuid,
      'amount': amount,
      'due_date': dueDate?.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'is_synced': isSynced,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Colunas de `public.installments`.
  Map<String, dynamic> toRemote() {
    return {
      'id': uuid,
      'sale_id': saleUuid,
      'amount': amount,
      'due_date': dueDate?.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    final rawSaleId = map['sale_id'];
    return Installment(
      id: rawId is int ? rawId : null,
      uuid: (map['uuid'] ?? (rawId is String ? rawId : '')) as String,
      saleId: rawSaleId is int ? rawSaleId : 0,
      saleUuid:
          (map['sale_uuid'] ?? (rawSaleId is String ? rawSaleId : ''))
              as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dueDate: _readDate(map['due_date']),
      paymentDate: _readDate(map['payment_date'] ?? map['date']),
      createdAt: _readDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']),
      isDeleted: map['is_deleted'] as bool? ?? false,
      isSynced: map['is_synced'] as bool? ?? false,
    );
  }

  Installment copyWith({
    int? id,
    String? uuid,
    int? saleId,
    String? saleUuid,
    double? amount,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? paymentDate,
    bool clearPaymentDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return Installment(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      saleId: saleId ?? this.saleId,
      saleUuid: saleUuid ?? this.saleUuid,
      amount: amount ?? this.amount,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      paymentDate: clearPaymentDate ? null : paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'Installment{id: $id, uuid: $uuid, saleId: $saleId, amount: $amount, dueDate: $dueDate, paymentDate: $paymentDate}';
  }
}

DateTime? _readDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString();
  if (text.isEmpty) return null;
  return DateTime.parse(text);
}

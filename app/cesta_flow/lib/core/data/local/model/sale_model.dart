import 'package:objectbox/objectbox.dart';

@Entity()
class Sale {
  @Id(assignable: true)
  int? id;
  String uuid;
  @Index()
  final int customerId;
  final String customerUuid;
  final String? userId;
  final double price;
  final double amountPaid;
  final int installments;
  @Property(type: PropertyType.dateNano)
  final DateTime createdAt;
  @Property(type: PropertyType.dateNano)
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isSynced;

  Sale({
    this.id,
    required this.uuid,
    required this.customerId,
    this.customerUuid = '',
    this.userId,
    required this.price,
    this.amountPaid = 0,
    this.installments = 1,
    DateTime? createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'customer_id': customerId,
      'customer_uuid': customerUuid,
      'user_id': userId,
      'price': price,
      'amount_paid': amountPaid,
      'installments': installments,
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

  /// Colunas de `public.sales`. `customer_id` remoto é o uuid do cliente.
  Map<String, dynamic> toRemote() {
    return {
      'id': uuid,
      'user_id': userId,
      'customer_id': customerUuid,
      'price': price,
      'amount_paid': amountPaid,
      'installments': installments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    final rawCustomerId = map['customer_id'];
    return Sale(
      id: rawId is int ? rawId : null,
      uuid: (map['uuid'] ?? (rawId is String ? rawId : '')) as String,
      customerId: rawCustomerId is int ? rawCustomerId : 0,
      customerUuid:
          (map['customer_uuid'] ??
                  (rawCustomerId is String ? rawCustomerId : ''))
              as String,
      userId: map['user_id'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0,
      installments: (map['installments'] as num?)?.toInt() ?? 1,
      createdAt:
          _readDate(map['created_at'] ?? map['date']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']),
      isDeleted: map['is_deleted'] as bool? ?? false,
      isSynced: map['is_synced'] as bool? ?? false,
    );
  }

  Sale copyWith({
    int? id,
    String? uuid,
    int? customerId,
    String? customerUuid,
    String? userId,
    bool clearUserId = false,
    double? price,
    double? amountPaid,
    int? installments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return Sale(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      customerId: customerId ?? this.customerId,
      customerUuid: customerUuid ?? this.customerUuid,
      userId: clearUserId ? null : userId ?? this.userId,
      price: price ?? this.price,
      amountPaid: amountPaid ?? this.amountPaid,
      installments: installments ?? this.installments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'Sale{id: $id, uuid: $uuid, customerId: $customerId, price: $price, amountPaid: $amountPaid, installments: $installments, createdAt: $createdAt}';
  }
}

DateTime? _readDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString();
  if (text.isEmpty) return null;
  return DateTime.parse(text);
}

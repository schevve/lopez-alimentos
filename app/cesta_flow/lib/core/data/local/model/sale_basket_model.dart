import 'package:objectbox/objectbox.dart';

@Entity()
class SaleBasket {
  @Id(assignable: true)
  int? id;
  @Index()
  final int saleId;
  @Index()
  final int basketId;
  final String saleUuid;
  final String basketUuid;
  final int quantity;
  @Property(type: PropertyType.dateNano)
  final DateTime createdAt;
  @Property(type: PropertyType.dateNano)
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isSynced;

  SaleBasket({
    this.id,
    required this.saleId,
    required this.basketId,
    required this.saleUuid,
    required this.basketUuid,
    required this.quantity,
    DateTime? createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sale_id': saleId,
      'basket_id': basketId,
      'sale_uuid': saleUuid,
      'basket_uuid': basketUuid,
      'quantity': quantity,
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

  /// Colunas de `public.sale_baskets`. A chave remota é (sale_id, basket_id).
  Map<String, dynamic> toRemote() {
    final stamp = (updatedAt ?? createdAt).toUtc().toIso8601String();
    return {
      'sale_id': saleUuid,
      'basket_id': basketUuid,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': stamp,
    };
  }

  factory SaleBasket.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    return SaleBasket(
      id: rawId is int ? rawId : null,
      saleId: map['sale_id'] is int ? map['sale_id'] as int : 0,
      basketId: map['basket_id'] is int ? map['basket_id'] as int : 0,
      saleUuid:
          (map['sale_uuid'] ?? (map['sale_id'] is String ? map['sale_id'] : ''))
              as String,
      basketUuid:
          (map['basket_uuid'] ??
                  (map['basket_id'] is String ? map['basket_id'] : ''))
              as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      createdAt: _readDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']),
      isDeleted: map['is_deleted'] as bool? ?? false,
      isSynced: map['is_synced'] as bool? ?? false,
    );
  }

  SaleBasket copyWith({
    int? id,
    int? saleId,
    int? basketId,
    String? saleUuid,
    String? basketUuid,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return SaleBasket(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      basketId: basketId ?? this.basketId,
      saleUuid: saleUuid ?? this.saleUuid,
      basketUuid: basketUuid ?? this.basketUuid,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

DateTime? _readDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString();
  if (text.isEmpty) return null;
  return DateTime.parse(text);
}

import 'package:objectbox/objectbox.dart';

@Entity()
class Basket {
  @Id(assignable: true)
  int? id;
  String uuid;
  final String name;
  final double price;
  @Property(type: PropertyType.dateNano)
  final DateTime createdAt;
  @Property(type: PropertyType.dateNano)
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isSynced;

  Basket({
    this.id,
    required this.uuid,
    this.name = '',
    required this.price,
    DateTime? createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'name': name,
      'price': price,
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

  /// Colunas de `public.baskets`, com `price` a ser criado no Supabase.
  Map<String, dynamic> toRemote() {
    final stamp = (updatedAt ?? createdAt).toUtc().toIso8601String();
    return {
      'id': uuid,
      'name': name,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': stamp,
    };
  }

  factory Basket.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    return Basket(
      id: rawId is int ? rawId : null,
      uuid: (map['uuid'] ?? (rawId is String ? rawId : '')) as String,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      createdAt: _readDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']),
      isDeleted: map['is_deleted'] as bool? ?? false,
      isSynced: map['is_synced'] as bool? ?? false,
    );
  }

  Basket copyWith({
    int? id,
    String? uuid,
    String? name,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return Basket(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      price: price ?? this.price,
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

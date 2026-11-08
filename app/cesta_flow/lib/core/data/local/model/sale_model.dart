import 'package:objectbox/objectbox.dart';

@Entity()
class Sale {
  @Id(assignable: true)
  int? id;
  String uuid;
  @Index()
  final int customerId;
  final String productName;
  final double price;
  final int quantity;
  @Property(type: PropertyType.dateNano)
  final DateTime date;
  final String description;
  final bool isBlocked;
  final bool isDeleted;
  final bool isSynced;

  Sale({
    this.id,
    required this.uuid,
    required this.customerId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.date,
    required this.description,
    this.isBlocked = false,
    this.isDeleted = false,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'customer_id': customerId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'description': description,
      'is_blocked': isBlocked,
      'is_deleted': isDeleted,
      'is_synced': isSynced,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      customerId: map['customer_id'] as int,
      productName: map['product_name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String,
      isBlocked: map['is_blocked'] as bool? ?? false,
      isDeleted: map['is_deleted'] as bool? ?? false,
      isSynced: map['is_synced'] as bool? ?? false,
    );
  }

  Sale copyWith({
    int? id,
    String? uuid,
    int? customerId,
    String? productName,
    double? price,
    int? quantity,
    DateTime? date,
    String? description,
    bool? isBlocked,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return Sale(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      customerId: customerId ?? this.customerId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      description: description ?? this.description,
      isBlocked: isBlocked ?? this.isBlocked,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'Sale{id: $id, uuid: $uuid, customerId: $customerId, productName: $productName, price: $price, quantity: $quantity, date: $date, description: $description, isBlocked: $isBlocked, isDeleted: $isDeleted, isSynced: $isSynced}';
  }
}

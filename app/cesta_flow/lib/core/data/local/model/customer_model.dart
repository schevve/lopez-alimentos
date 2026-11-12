import 'package:objectbox/objectbox.dart';

@Entity()
class Customer {
  @Id(assignable: true)
  int? id;
  String uuid;
  final String? userId;
  final String name;
  @Property(type: PropertyType.dateNano)
  final DateTime? dateOfBirth;
  final String? email;
  final String phone;
  final String address;
  final String addressNumber;
  final String city;
  final String state;
  final String? cep;
  @Unique()
  final String documentCPF;
  @Unique()
  final String? documentRG;
  final double? score;
  final bool isBlocked;
  final bool isDeleted;
  final bool isSynced;
  @Property(type: PropertyType.dateNano)
  final DateTime createdAt;
  @Property(type: PropertyType.dateNano)
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.uuid,
    this.userId,
    required this.name,
    required this.dateOfBirth,
    this.email,
    required this.phone,
    required this.address,
    required this.addressNumber,
    required this.city,
    required this.state,
    this.cep,
    required this.documentCPF,
    this.documentRG,
    this.score,
    this.isBlocked = false,
    this.isDeleted = false,
    this.isSynced = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Mapa local, inclusive para a base antiga. O id inteiro é só do ObjectBox.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'user_id': userId,
      'name': name,
      'date_of_birth': _dateOnly(dateOfBirth),
      'email': email,
      'phone': phone,
      'address': address,
      'address_number': addressNumber,
      'city': city,
      'state': state,
      'cep': cep,
      'cpf': documentCPF,
      'rg': documentRG,
      'score': score,
      'is_blocked': isBlocked,
      'is_deleted': isDeleted,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Colunas de `public.customers`. Sem região, sem flags locais.
  Map<String, dynamic> toRemote() {
    return {
      'id': uuid,
      'user_id': userId,
      'name': name,
      'date_of_birth': _dateOnly(dateOfBirth),
      'email': email,
      'phone': phone,
      'address': address,
      'address_number': addressNumber,
      'city': city,
      'state': state,
      'cep': cep,
      'cpf': documentCPF,
      'rg': documentRG,
      'score': score,
      'is_blocked': isBlocked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    return Customer(
      id: rawId is int ? rawId : null,
      uuid: (map['uuid'] ?? (rawId is String ? rawId : '')) as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String? ?? '',
      dateOfBirth: _readDate(map['date_of_birth']),
      email: map['email'] as String?,
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      addressNumber:
          (map['address_number'] ??
                  map['addres_number'] ??
                  map['adress_number'])
              as String? ??
          '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      cep: map['cep'] as String?,
      documentCPF: (map['cpf'] ?? map['document_cpf']) as String? ?? '',
      documentRG: (map['rg'] ?? map['document_rg']) as String?,
      score: (map['score'] as num?)?.toDouble(),
      isBlocked: map['is_blocked'] as bool? ?? false,
      isDeleted: map['is_deleted'] as bool? ?? false,
      isSynced: map['is_synced'] as bool? ?? false,
      createdAt: _readDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']),
    );
  }

  Customer copyWith({
    int? id,
    String? uuid,
    String? userId,
    bool clearUserId = false,
    String? name,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? email,
    String? phone,
    String? address,
    String? addressNumber,
    String? city,
    String? state,
    String? cep,
    String? documentCPF,
    String? documentRG,
    double? score,
    bool clearScore = false,
    bool? isBlocked,
    bool? isDeleted,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    return Customer(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: clearUserId ? null : userId ?? this.userId,
      name: name ?? this.name,
      dateOfBirth: clearDateOfBirth ? null : dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      addressNumber: addressNumber ?? this.addressNumber,
      city: city ?? this.city,
      state: state ?? this.state,
      cep: cep ?? this.cep,
      documentCPF: documentCPF ?? this.documentCPF,
      documentRG: documentRG ?? this.documentRG,
      score: clearScore ? null : score ?? this.score,
      isBlocked: isBlocked ?? this.isBlocked,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, uuid: $uuid, name: $name, documentCPF: $documentCPF, score: $score, isBlocked: $isBlocked}';
  }
}

String? _dateOnly(DateTime? date) {
  if (date == null) return null;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime? _readDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString();
  if (text.isEmpty) return null;
  return DateTime.parse(text);
}

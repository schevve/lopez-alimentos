import 'package:objectbox/objectbox.dart';

@Entity()
class Customer {
  @Id(assignable: true)
  int? id;
  String uuid;
  final String name;
  @Property(type: PropertyType.dateNano)
  final DateTime dateOfBirth;
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
  final int? score;
  final bool isBlocked;
  final bool isDeleted;
  final bool isSynced;

  Customer({
    this.id,
    required this.uuid,
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
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'email': email,
      'phone': phone,
      'address': address,
      'address_number': addressNumber,
      'city': city,
      'state': state,
      'cep': cep,
      'document_cpf': documentCPF,
      'document_rg': documentRG,
      'score': score,
      'is_blocked': isBlocked,
      'is_deleted': isDeleted,
      'is_synced': isSynced,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      dateOfBirth: DateTime.parse(map['date_of_birth'] as String),
      email: map['email'] as String?,
      phone: map['phone'] as String,
      address: map['address'] as String,
      addressNumber:
          (map['address_number'] ?? map['address_number']) as String? ?? '',
      city: map['city'] as String,
      state: map['state'] as String? ?? '',
      cep: map['cep'] as String?,
      documentCPF: map['document_cpf'] as String,
      documentRG: map['document_rg'] as String?,
      score: map['score'] as int?,
      isBlocked: map['is_blocked'] as bool? ?? false,
      isDeleted: map['is_deleted'] as bool? ?? false,
      isSynced: map['is_synced'] as bool? ?? false,
    );
  }

  Customer copyWith({
    int? id,
    String? uuid,
    String? name,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
    String? address,
    String? addressNumber,
    String? city,
    String? state,
    String? cep,
    String? documentCPF,
    String? documentRG,
    int? score,
    bool clearScore = false,
    bool? isBlocked,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return Customer(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
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
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, dateOfBirth: $dateOfBirth, email: $email, phone: $phone, address: $address, addressNumber: $addressNumber, city: $city, state: $state, cep: $cep, documentCPF: $documentCPF, documentRG: $documentRG, isBlocked: $isBlocked, isDeleted: $isDeleted, isSynced: $isSynced}';
  }
}

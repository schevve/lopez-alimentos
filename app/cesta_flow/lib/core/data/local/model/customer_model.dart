import 'package:objectbox/objectbox.dart';

@Entity()
class Customer {
  @Id(assignable: true)
  int? id;
  final String name;
  @Property(type: PropertyType.dateNano)
  final DateTime dateOfBirth;
  final String? email;
  final String phone;
  final String address;
  @Property(uid: 818118996813678362)
  final String adressNumber;
  final String city;
  final String state;
  final String? cep;
  @Unique()
  final String documentCPF;
  @Unique()
  final String? documentRG;
  final int? score;

  Customer({
    this.id,
    required this.name,
    required this.dateOfBirth,
    this.email,
    required this.phone,
    required this.address,
    required this.adressNumber,
    required this.city,
    required this.state,
    this.cep,
    required this.documentCPF,
    this.documentRG,
    this.score,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'email': email,
      'phone': phone,
      'address': address,
      'adress_number': adressNumber,
      'city': city,
      'state': state,
      'cep': cep,
      'document_cpf': documentCPF,
      'document_rg': documentRG,
      'score': score,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      dateOfBirth: DateTime.parse(map['date_of_birth'] as String),
      email: map['email'] as String?,
      phone: map['phone'] as String,
      address: map['address'] as String,
      adressNumber: map['adress_number'] as String? ?? '',
      city: map['city'] as String,
      state: map['state'] as String? ?? '',
      cep: map['cep'] as String?,
      documentCPF: map['document_cpf'] as String,
      documentRG: map['document_rg'] as String?,
      score: map['score'] as int?,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
    String? address,
    String? adressNumber,
    String? city,
    String? state,
    String? cep,
    String? documentCPF,
    String? documentRG,
    int? score,
    bool clearScore = false,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      adressNumber: adressNumber ?? this.adressNumber,
      city: city ?? this.city,
      state: state ?? this.state,
      cep: cep ?? this.cep,
      documentCPF: documentCPF ?? this.documentCPF,
      documentRG: documentRG ?? this.documentRG,
      score: clearScore ? null : score ?? this.score,
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, dateOfBirth: $dateOfBirth, email: $email, phone: $phone, address: $address, adress_number: $adressNumber, city: $city, state: $state, cep: $cep, documentCPF: $documentCPF, documentRG: $documentRG}';
  }
}

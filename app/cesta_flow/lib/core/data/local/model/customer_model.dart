class Customer {
  final int? id;
  final String name;
  final DateTime dateOfBirth;
  final String? email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String? cep;
  final String documentCPF;
  final String? documentRG;

  Customer({
    this.id,
    required this.name,
    required this.dateOfBirth,
    this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    this.cep,
    required this.documentCPF,
    this.documentRG,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'cep': cep,
      'document_cpf': documentCPF,
      'document_rg': documentRG,
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
      email: map['email'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      state: map['state'] as String? ?? '',
      cep: map['cep'] as String,
      documentCPF: map['document_cpf'] as String,
      documentRG: map['document_rg'] as String?,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? cep,
    String? documentCPF,
    String? documentRG,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      cep: cep ?? this.cep,
      documentCPF: documentCPF ?? this.documentCPF,
      documentRG: documentRG ?? this.documentRG,
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, dateOfBirth: $dateOfBirth, email: $email, phone: $phone, address: $address, city: $city, state: $state, cep: $cep, documentCPF: $documentCPF, documentRG: $documentRG}';
  }
}

enum ProfileRole {
  user,
  admin;

  static ProfileRole fromDatabase(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return ProfileRole.admin;
      case 'USER':
      default:
        return ProfileRole.user;
    }
  }

  String toDatabase() {
    switch (this) {
      case ProfileRole.admin:
        return 'ADMIN';
      case ProfileRole.user:
        return 'USER';
    }
  }
}

class Profile {
  final String id;
  final String? firstName;
  final String? lastName;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final ProfileRole role;

  Profile({
    required this.id,
    this.firstName,
    this.lastName,
    this.updatedAt,
    this.deletedAt,
    this.role = ProfileRole.user,
  });

  String get displayName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    return [first, last].where((part) => part.isNotEmpty).join(' ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'role': role.toDatabase(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      updatedAt: _parseDateTime(map['updated_at']),
      deletedAt: _parseDateTime(map['deleted_at']),
      role: ProfileRole.fromDatabase(map['role'] as String? ?? 'USER'),
    );
  }

  Profile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    DateTime? updatedAt,
    DateTime? deletedAt,
    ProfileRole? role,
    bool clearDeletedAt = false,
  }) {
    return Profile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'Profile{id: $id, firstName: $firstName, lastName: $lastName, '
        'updatedAt: $updatedAt, deletedAt: $deletedAt, role: $role}';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
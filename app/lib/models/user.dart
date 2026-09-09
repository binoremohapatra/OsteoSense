class User {
  final int? id;
  final String fullName;
  final String phoneNumber;
  final String password;
  final String? healthCenterId;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.password,
    this.healthCenterId,
    this.location,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'password': password,
      'health_center_id': healthCenterId,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
      'healthCenterId': healthCenterId,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: (map['full_name'] ?? map['fullName']) as String,
      phoneNumber: (map['phone_number'] ?? map['phoneNumber']) as String,
      password: map['password'] as String,
      healthCenterId: (map['health_center_id'] ?? map['healthCenterId']) as String?,
      location: map['location'] as String?,
      createdAt: DateTime.parse(map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  User copyWith({
    int? id,
    String? fullName,
    String? phoneNumber,
    String? password,
    String? healthCenterId,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      healthCenterId: healthCenterId ?? this.healthCenterId,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

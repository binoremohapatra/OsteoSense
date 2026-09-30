class Patient {
  final int? id;
  final String? serverId;
  final String name;
  final int age;
  final String gender;
  final String? contact;
  final String? village;
  final String? address;
  final String? occupation;
  final double? weightKg;
  final double? heightCm;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Patient({
    this.id,
    this.serverId,
    required this.name,
    required this.age,
    required this.gender,
    this.contact,
    this.village,
    this.address,
    this.occupation,
    this.weightKg,
    this.heightCm,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Computed BMI — returns null when weight or height is missing.
  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final heightM = heightCm! / 100.0;
    return weightKg! / (heightM * heightM);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'name': name,
      'age': age,
      'gender': gender,
      'contact': contact,
      'village': village,
      'address': address,
      'occupation': occupation,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      name: map['name'] as String,
      age: map['age'] as int,
      gender: map['gender'] as String,
      contact: map['contact'] as String?,
      village: map['village'] as String?,
      address: map['address'] as String?,
      occupation: map['occupation'] as String?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      synced: (map['synced'] as int) == 1,
    );
  }

  Patient copyWith({
    int? id,
    String? serverId,
    String? name,
    int? age,
    String? gender,
    String? contact,
    String? village,
    String? address,
    String? occupation,
    double? weightKg,
    double? heightCm,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Patient(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      contact: contact ?? this.contact,
      village: village ?? this.village,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

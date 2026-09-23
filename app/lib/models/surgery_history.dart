class SurgeryHistory {
  final int? id;
  final int patientId;
  final String joint;
  final String side;
  final String surgeryType;
  final String? surgeryDate;
  final String? reason;
  final String? hospital;
  final bool? implantPresent;
  final DateTime? createdAt;

  SurgeryHistory({
    this.id,
    required this.patientId,
    required this.joint,
    required this.side,
    required this.surgeryType,
    this.surgeryDate,
    this.reason,
    this.hospital,
    this.implantPresent,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'joint': joint,
      'side': side,
      'surgery_type': surgeryType,
      'surgery_date': surgeryDate,
      'reason': reason,
      'hospital': hospital,
      'implant_present': implantPresent == true ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory SurgeryHistory.fromMap(Map<String, dynamic> map) {
    return SurgeryHistory(
      id: map['id'] as int?,
      patientId: map['patient_id'] as int,
      joint: map['joint'] as String,
      side: map['side'] as String,
      surgeryType: map['surgery_type'] as String,
      surgeryDate: map['surgery_date'] as String?,
      reason: map['reason'] as String?,
      hospital: map['hospital'] as String?,
      implantPresent: (map['implant_present'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }
}

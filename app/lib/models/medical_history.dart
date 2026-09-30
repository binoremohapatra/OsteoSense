class MedicalHistory {
  final int? id;
  final int patientId;
  final String joint;
  final String side;
  final bool? previousDiagnosis;
  final bool? previousJointPain;
  final bool? chronicJointProblems;
  final bool? previousInflammation;
  final bool? previousCartilageProblems;
  final bool? previousLigamentProblems;
  final bool? previousFracture;
  final bool? hasPastInjury;
  final String? injuryType;
  final String? injuryDate;
  final String? injuryMechanism;
  final String? injurySeverity;
  final bool? medicalTreatmentRequired;
  final bool? immobilizationRequired;
  final bool? physiotherapyPerformed;
  final String? currentSymptomsAfterInjury;
  final DateTime? createdAt;

  MedicalHistory({
    this.id,
    required this.patientId,
    required this.joint,
    required this.side,
    this.previousDiagnosis,
    this.previousJointPain,
    this.chronicJointProblems,
    this.previousInflammation,
    this.previousCartilageProblems,
    this.previousLigamentProblems,
    this.previousFracture,
    this.hasPastInjury,
    this.injuryType,
    this.injuryDate,
    this.injuryMechanism,
    this.injurySeverity,
    this.medicalTreatmentRequired,
    this.immobilizationRequired,
    this.physiotherapyPerformed,
    this.currentSymptomsAfterInjury,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'joint': joint,
      'side': side,
      'previous_diagnosis': previousDiagnosis == true ? 1 : 0,
      'previous_joint_pain': previousJointPain == true ? 1 : 0,
      'chronic_joint_problems': chronicJointProblems == true ? 1 : 0,
      'previous_inflammation': previousInflammation == true ? 1 : 0,
      'previous_cartilage_problems': previousCartilageProblems == true ? 1 : 0,
      'previous_ligament_problems': previousLigamentProblems == true ? 1 : 0,
      'previous_fracture': previousFracture == true ? 1 : 0,
      'has_past_injury': hasPastInjury == true ? 1 : 0,
      'injury_type': injuryType,
      'injury_date': injuryDate,
      'injury_mechanism': injuryMechanism,
      'injury_severity': injurySeverity,
      'medical_treatment_required': medicalTreatmentRequired == true ? 1 : 0,
      'immobilization_required': immobilizationRequired == true ? 1 : 0,
      'physiotherapy_performed': physiotherapyPerformed == true ? 1 : 0,
      'current_symptoms_after_injury': currentSymptomsAfterInjury,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory MedicalHistory.fromMap(Map<String, dynamic> map) {
    return MedicalHistory(
      id: map['id'] as int?,
      patientId: map['patient_id'] as int,
      joint: map['joint'] as String,
      side: map['side'] as String,
      previousDiagnosis: (map['previous_diagnosis'] as int?) == 1,
      previousJointPain: (map['previous_joint_pain'] as int?) == 1,
      chronicJointProblems: (map['chronic_joint_problems'] as int?) == 1,
      previousInflammation: (map['previous_inflammation'] as int?) == 1,
      previousCartilageProblems: (map['previous_cartilage_problems'] as int?) == 1,
      previousLigamentProblems: (map['previous_ligament_problems'] as int?) == 1,
      previousFracture: (map['previous_fracture'] as int?) == 1,
      hasPastInjury: (map['has_past_injury'] as int?) == 1,
      injuryType: map['injury_type'] as String?,
      injuryDate: map['injury_date'] as String?,
      injuryMechanism: map['injury_mechanism'] as String?,
      injurySeverity: map['injury_severity'] as String?,
      medicalTreatmentRequired: (map['medical_treatment_required'] as int?) == 1,
      immobilizationRequired: (map['immobilization_required'] as int?) == 1,
      physiotherapyPerformed: (map['physiotherapy_performed'] as int?) == 1,
      currentSymptomsAfterInjury: map['current_symptoms_after_injury'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }
}

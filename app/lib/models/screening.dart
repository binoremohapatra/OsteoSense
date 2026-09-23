class Screening {
  final int? id;
  final String? serverId;
  final int patientId;
  final int userId;
  final DateTime screeningDate;
  final String? jointId;
  final String? side;
  final int? painLevel;
  final String? stiffnessDuration;
  final bool? swelling;
  final String? pastInjury;
  final int? mriKlGrade;
  final String? gaitData;
  final String? symptomsMap;
  final String? functionalMap;
  final String? riskLevel;
  final double? confidence;
  final String? contributingFactors;
  final String? aiReasoning;
  final String? doctorRecommendations;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Screening({
    this.id,
    this.serverId,
    required this.patientId,
    required this.userId,
    DateTime? screeningDate,
    this.jointId,
    this.side,
    this.painLevel,
    this.stiffnessDuration,
    this.swelling,
    this.pastInjury,
    this.mriKlGrade,
    this.gaitData,
    this.symptomsMap,
    this.functionalMap,
    this.riskLevel,
    this.confidence,
    this.contributingFactors,
    this.aiReasoning,
    this.doctorRecommendations,
    this.synced = false,
    this.createdAt,
    this.updatedAt,
  }) : screeningDate = screeningDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'patient_id': patientId,
      'user_id': userId,
      'screening_date': screeningDate.toIso8601String(),
      'joint_id': jointId,
      'side': side,
      'pain_level': painLevel,
      'stiffness_duration': stiffnessDuration,
      'swelling': swelling == true ? 1 : 0,
      'past_injury': pastInjury,
      'mri_kl_grade': mriKlGrade,
      'gait_data': gaitData,
      'symptoms_map': symptomsMap,
      'functional_map': functionalMap,
      'risk_level': riskLevel,
      'confidence': confidence,
      'contributing_factors': contributingFactors,
      'ai_reasoning': aiReasoning,
      'doctor_recommendations': doctorRecommendations,
      'synced': synced ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Screening.fromMap(Map<String, dynamic> map) {
    return Screening(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      patientId: map['patient_id'] as int,
      userId: map['user_id'] as int,
      screeningDate: DateTime.parse(map['screening_date'] as String),
      jointId: map['joint_id'] as String?,
      side: map['side'] as String?,
      painLevel: map['pain_level'] as int?,
      stiffnessDuration: map['stiffness_duration'] as String?,
      swelling: (map['swelling'] as int?) == 1,
      pastInjury: map['past_injury'] as String?,
      mriKlGrade: map['mri_kl_grade'] as int?,
      gaitData: map['gait_data'] as String?,
      symptomsMap: map['symptoms_map'] as String?,
      functionalMap: map['functional_map'] as String?,
      riskLevel: map['risk_level'] as String?,
      confidence: map['confidence'] as double?,
      contributingFactors: map['contributing_factors'] as String?,
      aiReasoning: map['ai_reasoning'] as String?,
      doctorRecommendations: map['doctor_recommendations'] as String?,
      synced: (map['synced'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Screening copyWith({
    int? id,
    String? serverId,
    int? patientId,
    int? userId,
    DateTime? screeningDate,
    String? jointId,
    String? side,
    int? painLevel,
    String? stiffnessDuration,
    bool? swelling,
    String? pastInjury,
    int? mriKlGrade,
    String? gaitData,
    String? symptomsMap,
    String? functionalMap,
    String? riskLevel,
    double? confidence,
    String? contributingFactors,
    String? aiReasoning,
    String? doctorRecommendations,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Screening(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      patientId: patientId ?? this.patientId,
      userId: userId ?? this.userId,
      screeningDate: screeningDate ?? this.screeningDate,
      jointId: jointId ?? this.jointId,
      side: side ?? this.side,
      painLevel: painLevel ?? this.painLevel,
      stiffnessDuration: stiffnessDuration ?? this.stiffnessDuration,
      swelling: swelling ?? this.swelling,
      pastInjury: pastInjury ?? this.pastInjury,
      mriKlGrade: mriKlGrade ?? this.mriKlGrade,
      gaitData: gaitData ?? this.gaitData,
      symptomsMap: symptomsMap ?? this.symptomsMap,
      functionalMap: functionalMap ?? this.functionalMap,
      riskLevel: riskLevel ?? this.riskLevel,
      confidence: confidence ?? this.confidence,
      contributingFactors: contributingFactors ?? this.contributingFactors,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      doctorRecommendations: doctorRecommendations ?? this.doctorRecommendations,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum RiskLevel {
  low,
  medium,
  high,
}

extension RiskLevelExtension on RiskLevel {
  String get value {
    switch (this) {
      case RiskLevel.low:
        return 'low';
      case RiskLevel.medium:
        return 'medium';
      case RiskLevel.high:
        return 'high';
    }
  }

  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }
}

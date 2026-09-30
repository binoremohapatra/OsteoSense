class MedicalImage {
  final int? id;
  final int patientId;
  final String joint;
  final String side;
  final String imageType; // X-Ray, MRI, Ultrasound, Clinical Photograph, Medical Report
  final String filePath;
  final String source; // 'user_upload', 'camera', etc.
  final DateTime? createdAt;

  MedicalImage({
    this.id,
    required this.patientId,
    required this.joint,
    required this.side,
    required this.imageType,
    required this.filePath,
    required this.source,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'joint': joint,
      'side': side,
      'image_type': imageType,
      'file_path': filePath,
      'source': source,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory MedicalImage.fromMap(Map<String, dynamic> map) {
    return MedicalImage(
      id: map['id'] as int?,
      patientId: map['patient_id'] as int,
      joint: map['joint'] as String,
      side: map['side'] as String,
      imageType: map['image_type'] as String,
      filePath: map['file_path'] as String,
      source: map['source'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }
}

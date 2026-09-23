import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:flutter/foundation.dart';

class TFLiteService {
  static TFLiteService? _instance;
  tfl.Interpreter? _interpreter;
  bool _isModelLoaded = false;

  factory TFLiteService() {
    _instance ??= TFLiteService._internal();
    return _instance!;
  }

  TFLiteService._internal();

  bool get isModelLoaded => _isModelLoaded;

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      // Load the TFLite model
      // Note: You need to place your .tflite model in assets/models/
      // For this example, we'll use a placeholder approach
      _interpreter = await tfl.Interpreter.fromAsset('assets/models/oa_risk_model.tflite');
      _isModelLoaded = true;
      debugPrint('TFLite model loaded successfully');
    } catch (e) {
      // Model file is a placeholder or not available - use rule-based fallback
      debugPrint('TFLite model not available, using rule-based prediction: $e');
      _isModelLoaded = false;
    }
  }

  Future<RiskPrediction> predictRisk({
    required int painLevel,
    required String stiffnessDuration,
    required bool swelling,
    required String? pastInjury,
    required int mriKlGrade,
    required int age,
    required double weightKg,
    required double heightCm,
    required List<double> gaitFeatures,
    Map<String, dynamic>? symptomsMap,
    Map<String, dynamic>? functionalMap,
    List<double>? piezoFeatures,
    List<double>? emgFeatures,
  }) async {
    try {
      if (_isModelLoaded && _interpreter != null) {
        return await _predictWithModel(
          painLevel: painLevel,
          stiffnessDuration: stiffnessDuration,
          swelling: swelling,
          pastInjury: pastInjury,
          mriKlGrade: mriKlGrade,
          age: age,
          weightKg: weightKg,
          heightCm: heightCm,
          gaitFeatures: gaitFeatures,
          symptomsMap: symptomsMap,
          functionalMap: functionalMap,
          piezoFeatures: piezoFeatures,
          emgFeatures: emgFeatures,
        );
      } else {
        // Fallback to rule-based prediction
        return _predictWithRules(
          painLevel: painLevel,
          stiffnessDuration: stiffnessDuration,
          swelling: swelling,
          pastInjury: pastInjury,
          mriKlGrade: mriKlGrade,
          age: age,
          weightKg: weightKg,
          heightCm: heightCm,
          gaitFeatures: gaitFeatures,
          symptomsMap: symptomsMap,
          functionalMap: functionalMap,
          piezoFeatures: piezoFeatures,
          emgFeatures: emgFeatures,
        );
      }
    } catch (e) {
      debugPrint('Error predicting risk: $e');
      // Return default low risk on error
      return RiskPrediction(
        riskLevel: 'low',
        confidence: 0.5,
        contributingFactors: [],
        reasoning: 'Unable to analyze due to error. Please try again.',
      );
    }
  }

  Future<RiskPrediction> _predictWithModel({
    required int painLevel,
    required String stiffnessDuration,
    required bool swelling,
    required String? pastInjury,
    required int mriKlGrade,
    required int age,
    required double weightKg,
    required double heightCm,
    required List<double> gaitFeatures,
    Map<String, dynamic>? symptomsMap,
    Map<String, dynamic>? functionalMap,
    List<double>? piezoFeatures,
    List<double>? emgFeatures,
  }) async {
    // Prepare input features
    // Normalize features based on your model's expected input
    final input = _prepareInputFeatures(
      painLevel: painLevel,
      stiffnessDuration: stiffnessDuration,
      swelling: swelling,
      pastInjury: pastInjury,
      mriKlGrade: mriKlGrade,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      gaitFeatures: gaitFeatures,
      symptomsMap: symptomsMap,
      functionalMap: functionalMap,
      piezoFeatures: piezoFeatures,
      emgFeatures: emgFeatures,
    );

    // Prepare output buffer
    final output = List<double>.filled(3, 0).reshape([1, 3]);

    // Run inference
    _interpreter!.run(input, output);

    // Process output
    final probabilities = (output[0] as List).cast<double>();
    
    double maxVal = probabilities[0];
    int maxIndex = 0;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxVal) {
        maxVal = probabilities[i];
        maxIndex = i;
      }
    }
    
    final riskLevels = ['low', 'medium', 'high'];
    final predictedRisk = riskLevels[maxIndex];
    final confidence = probabilities[maxIndex];

    final contributingFactors = _identifyContributingFactors(
      painLevel: painLevel,
      stiffnessDuration: stiffnessDuration,
      swelling: swelling,
      pastInjury: pastInjury,
      mriKlGrade: mriKlGrade,
      gaitFeatures: gaitFeatures,
      symptomsMap: symptomsMap,
      functionalMap: functionalMap,
      piezoFeatures: piezoFeatures,
      emgFeatures: emgFeatures,
    );

    return RiskPrediction(
      riskLevel: predictedRisk,
      confidence: confidence,
      contributingFactors: contributingFactors,
      reasoning: _generateReasoning(predictedRisk, contributingFactors, confidence),
    );
  }

  RiskPrediction _predictWithRules({
    required int painLevel,
    required String stiffnessDuration,
    required bool swelling,
    required String? pastInjury,
    required int mriKlGrade,
    required int age,
    required double weightKg,
    required double heightCm,
    required List<double> gaitFeatures,
    Map<String, dynamic>? symptomsMap,
    Map<String, dynamic>? functionalMap,
    List<double>? piezoFeatures,
    List<double>? emgFeatures,
  }) {
    // Rule-based prediction as fallback
    double riskScore = 0;
    List<String> factors = [];

    // Pain level contribution (0-10)
    riskScore += painLevel * 0.3;
    if (painLevel >= 7) {
      factors.add('High pain level');
    } else if (painLevel >= 4) factors.add('Moderate pain level');

    // Stiffness duration contribution
    final stiffnessMinutes = _parseStiffnessDuration(stiffnessDuration);
    if (stiffnessMinutes > 30) {
      riskScore += 2.0;
      factors.add('Prolonged morning stiffness');
    } else if (stiffnessMinutes > 15) {
      riskScore += 1.0;
      factors.add('Morning stiffness');
    }

    // Swelling contribution
    if (swelling) {
      riskScore += 1.5;
      factors.add('Joint swelling');
    }

    // Past injury contribution
    if (pastInjury != null && pastInjury.isNotEmpty) {
      riskScore += 1.0;
      factors.add('History of joint injury');
    }

    if (mriKlGrade >= 2) {
      riskScore += 1.5;
      factors.add('MRI indicates structural joint damage (KL Grade $mriKlGrade)');
    }

    // Gait analysis contribution (if available)
    if (gaitFeatures.isNotEmpty) {
      final gaitScore = _analyzeGaitFeatures(gaitFeatures);
      riskScore += gaitScore;
      if (gaitScore > 1.0) factors.add('Abnormal gait pattern detected');
    }

    // Piezo / Joint Sound contribution
    if (piezoFeatures != null && piezoFeatures.isNotEmpty) {
      final piezoRMS = piezoFeatures[0]; 
      if (piezoRMS > 0.5) {
        riskScore += 1.5;
        factors.add('Elevated joint crepitus (sound) detected');
      }
    }

    // EMG / Muscle activity contribution
    if (emgFeatures != null && emgFeatures.isNotEmpty) {
      final emgRMS = emgFeatures[0];
      if (emgRMS > 0.4) {
        riskScore += 1.0;
        factors.add('Abnormal muscle guarding (EMG) detected');
      }
    }

    // Integrate multimodal features
    if (symptomsMap != null) {
      final painChars = symptomsMap['pain_characteristics'] as Map<String, dynamic>? ?? {};
      int sharpPain = 0;
      painChars.forEach((k, v) { if (v == true) sharpPain++; });
      if (sharpPain > 2) {
        riskScore += 1.0;
        factors.add('Multiple complex pain characteristics reported');
      }
    }
    
    if (functionalMap != null) {
      int severeLimits = 0;
      functionalMap.forEach((k, v) {
        if (v is num && v >= 2) severeLimits++;
      });
      if (severeLimits > 1) {
        riskScore += 1.5;
        factors.add('Significant functional limitations in daily activities');
      }
    }

    // Determine risk level based on score
    String riskLevel;
    double confidence;
    
    if (riskScore >= 5.0) {
      riskLevel = 'high';
      confidence = 0.85;
    } else if (riskScore >= 3.0) {
      riskLevel = 'medium';
      confidence = 0.75;
    } else {
      riskLevel = 'low';
      confidence = 0.70;
    }

    return RiskPrediction(
      riskLevel: riskLevel,
      confidence: confidence,
      contributingFactors: factors,
      reasoning: _generateReasoning(riskLevel, factors, confidence),
    );
  }

  List<List<double>> _prepareInputFeatures({
    required int painLevel,
    required String stiffnessDuration,
    required bool swelling,
    required String? pastInjury,
    required int mriKlGrade,
    required int age,
    required double weightKg,
    required double heightCm,
    required List<double> gaitFeatures,
    Map<String, dynamic>? symptomsMap,
    Map<String, dynamic>? functionalMap,
    List<double>? piezoFeatures,
    List<double>? emgFeatures,
  }) {
    // We extract 44 DSP features in Dart, gaitFeatures contains all of them.
    // Ensure the size is exactly 44 before appending clinical features
    final features = List<double>.from(gaitFeatures);
    
    while (features.length < 44) {
      features.add(0.0);
    }
    
    // Append 4 Clinical Features (Multimodal AI)
    features.add(painLevel.toDouble());
    features.add(_parseStiffnessDuration(stiffnessDuration).toDouble());
    features.add(swelling ? 1.0 : 0.0);
    features.add((pastInjury != null && pastInjury.isNotEmpty) ? 1.0 : 0.0);
    features.add(mriKlGrade.toDouble());

    // Append 4 Demographic Features
    features.add(age.toDouble());
    features.add(weightKg);
    features.add(heightCm);
    
    double bmi = 24.0;
    if (heightCm > 0) {
      bmi = weightKg / ((heightCm / 100.0) * (heightCm / 100.0));
    }
    features.add(bmi);
    
    // Append 9 Multimodal Features (Symptoms & Functional)
    final otherSymptoms = symptomsMap?['other_symptoms'] as Map<String, dynamic>? ?? {};
    features.add((otherSymptoms['Locking'] == true) ? 1.0 : 0.0);
    features.add((otherSymptoms['Clicking'] == true) ? 1.0 : 0.0);
    features.add((otherSymptoms['Grinding'] == true) ? 1.0 : 0.0);
    features.add((otherSymptoms['Instability'] == true) ? 1.0 : 0.0);
    
    final painChars = symptomsMap?['pain_characteristics'] as Map<String, dynamic>? ?? {};
    features.add((painChars['Aching'] == true) ? 1.0 : 0.0);
    
    features.add((functionalMap?['Standing'] as num?)?.toDouble() ?? 0.0);
    features.add((functionalMap?['Walking'] as num?)?.toDouble() ?? 0.0);
    features.add((functionalMap?['Stairs'] as num?)?.toDouble() ?? 0.0);
    features.add((functionalMap?['Chores'] as num?)?.toDouble() ?? 0.0);

    const expectedInputSize = 62;
    
    // Create 2D list for model input
    return [features.take(expectedInputSize).toList()];
  }

  int _parseStiffnessDuration(String duration) {
    // Parse stiffness duration string to minutes
    // Expected format: "30 minutes" or just "30"
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(duration);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 0;
  }

  double _analyzeGaitFeatures(List<double> gaitFeatures) {
    // Analyze gait features and return a risk contribution score
    if (gaitFeatures.isEmpty) return 0.0;
    
    final sum = gaitFeatures.fold<double>(0.0, (double prev, double curr) => prev + curr);
    final mean = sum / gaitFeatures.length;
    final varianceSum = gaitFeatures.fold<double>(0.0, (double prev, double curr) => prev + (curr - mean) * (curr - mean));
    final variance = varianceSum / gaitFeatures.length;
    
    // High variance might indicate irregular gait
    if (variance > 0.5) return 1.5;
    if (variance > 0.3) return 1.0;
    return 0.5;
  }

  List<String> _identifyContributingFactors({
    required int painLevel,
    required String stiffnessDuration,
    required bool swelling,
    required String? pastInjury,
    required int mriKlGrade,
    required List<double> gaitFeatures,
    Map<String, dynamic>? symptomsMap,
    Map<String, dynamic>? functionalMap,
    List<double>? piezoFeatures,
    List<double>? emgFeatures,
  }) {
    final factors = <String>[];
    
    if (painLevel >= 7) factors.add('Severe pain symptoms');
    if (painLevel >= 4 && painLevel < 7) factors.add('Moderate pain symptoms');
    
    final stiffnessMinutes = _parseStiffnessDuration(stiffnessDuration);
    if (stiffnessMinutes > 30) factors.add('Extended morning stiffness');
    if (stiffnessMinutes > 15) factors.add('Morning stiffness present');
    
    if (swelling) factors.add('Joint swelling observed');
    
    if (pastInjury != null && pastInjury.isNotEmpty) {
      factors.add('Previous joint injury history');
    }
    
    if (mriKlGrade >= 2) {
      factors.add('MRI structural damage present (KL Grade $mriKlGrade)');
    }
    
    if (gaitFeatures.isNotEmpty) {
      final gaitScore = _analyzeGaitFeatures(gaitFeatures);
      if (gaitScore > 1.0) factors.add('Gait irregularities detected');
    }
    
    if (piezoFeatures != null && piezoFeatures.isNotEmpty && piezoFeatures[0] > 0.5) {
      factors.add('Joint crepitus detected');
    }
    
    if (emgFeatures != null && emgFeatures.isNotEmpty && emgFeatures[0] > 0.4) {
      factors.add('Muscle guarding detected');
    }
    
    if (symptomsMap != null) {
      final other = symptomsMap['other_symptoms'] as Map<String, dynamic>? ?? {};
      if (other['Locking'] == true) factors.add('Joint locking reported');
      if (other['Instability'] == true) factors.add('Joint instability reported');
    }

    if (functionalMap != null) {
      int severeLimits = 0;
      functionalMap.forEach((k, v) {
        if (v is num && v >= 2) severeLimits++;
      });
      if (severeLimits > 1) {
        factors.add('Functional limitations impact daily activities');
      }
    }
    
    return factors;
  }

  String _generateReasoning(String riskLevel, List<String> factors, double confidence) {
    final buffer = StringBuffer();
    
    buffer.writeln('Based on the analysis of symptoms and gait patterns:');
    buffer.writeln();
    
    if (factors.isNotEmpty) {
      buffer.writeln('Key contributing factors:');
      for (final factor in factors) {
        buffer.writeln('• $factor');
      }
      buffer.writeln();
    }
    
    switch (riskLevel) {
      case 'high':
        buffer.writeln('The patient shows strong indicators of osteoarthritis risk.');
        buffer.writeln('Immediate medical consultation is recommended.');
        buffer.writeln('Consider referral to a specialist for further evaluation.');
        break;
      case 'medium':
        buffer.writeln('The patient shows moderate indicators of osteoarthritis risk.');
        buffer.writeln('Regular monitoring and preventive measures are advised.');
        buffer.writeln('Lifestyle modifications may help slow progression.');
        break;
      case 'low':
        buffer.writeln('The patient shows minimal indicators of osteoarthritis risk.');
        buffer.writeln('Continue regular health monitoring.');
        buffer.writeln('Maintain healthy lifestyle practices for joint health.');
        break;
    }
    
    buffer.writeln();
    buffer.writeln('Analysis confidence: ${(confidence * 100).toStringAsFixed(1)}%');
    
    return buffer.toString();
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}

class RiskPrediction {
  final String riskLevel;
  final double confidence;
  final List<String> contributingFactors;
  final String reasoning;

  RiskPrediction({
    required this.riskLevel,
    required this.confidence,
    required this.contributingFactors,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() {
    return {
      'risk_level': riskLevel,
      'confidence': confidence,
      'contributing_factors': contributingFactors,
      'reasoning': reasoning,
    };
  }

  factory RiskPrediction.fromJson(Map<String, dynamic> json) {
    return RiskPrediction(
      riskLevel: json['risk_level'] as String,
      confidence: json['confidence'] as double,
      contributingFactors: List<String>.from(json['contributing_factors'] as List),
      reasoning: json['reasoning'] as String,
    );
  }
}

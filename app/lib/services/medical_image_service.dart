import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import '../utils/constants.dart';
import 'tflite_service.dart';

// ============================================================================
// MedicalImageService
//
// Provides scan-type detection (X-ray / MRI / CT / USG) and osteoarthritis
// image analysis for joint scans.
// ============================================================================

enum ScanModality { xray, mri, ct, usg, unknown }

class ScanBiomarkers {
  final int estimatedKLGrade;
  final double jointSpaceProxy;
  final double osteophyteScore;
  final double sclerosisScore;
  final double cartilageIntegrity;
  final double effusionScore; // New: Joint fluid / inflammation proxy
  final double imageQuality;

  const ScanBiomarkers({
    required this.estimatedKLGrade,
    required this.jointSpaceProxy,
    required this.osteophyteScore,
    required this.sclerosisScore,
    required this.cartilageIntegrity,
    this.effusionScore = 0.0,
    required this.imageQuality,
  });

  Map<String, dynamic> toJson() => {
        'estimated_kl_grade': estimatedKLGrade,
        'joint_space_proxy': jointSpaceProxy,
        'osteophyte_score': osteophyteScore,
        'sclerosis_score': sclerosisScore,
        'cartilage_integrity': cartilageIntegrity,
        'effusion_score': effusionScore,
        'image_quality': imageQuality,
      };
}

class ScanAnalysisResult {
  final ScanModality modality;
  final String modalityLabel;
  final double modalityConfidence;
  final ScanBiomarkers biomarkers;
  final double imageRiskScore;
  final int suggestedKLGrade;
  final List<String> findings;
  final String interpretation;
  final bool serverValidated;
  final RiskPrediction? enrichedPrediction;

  const ScanAnalysisResult({
    required this.modality,
    required this.modalityLabel,
    required this.modalityConfidence,
    required this.biomarkers,
    required this.imageRiskScore,
    required this.suggestedKLGrade,
    required this.findings,
    required this.interpretation,
    this.serverValidated = false,
    this.enrichedPrediction,
  });
}

class MedicalImageService {
  static MedicalImageService? _instance;

  factory MedicalImageService() {
    _instance ??= MedicalImageService._internal();
    return _instance!;
  }

  MedicalImageService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<ScanAnalysisResult> analyzeImage({
    required String imagePath,
    String jointType = 'knee',
    RiskPrediction? existingRisk,
  }) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return _errorResult('Image file not found.');
      }

      final bytes = await file.readAsBytes();

      // Decode image to actual pixels for local heuristics
      final decoded = img.decodeImage(bytes);
      List<int> pixelData = [];
      if (decoded != null) {
        // Do NOT resize (resizing ruins entropy/noise metrics for MRI/USG).
        // Instead, sample uniformly to match backend numpy behavior and keep it fast.
        final step = math.max(1, decoded.length ~/ 80000);
        int i = 0;
        for (final p in decoded) {
          if (i % step == 0) {
            pixelData.add((p.r * 0.299 + p.g * 0.587 + p.b * 0.114).toInt());
          }
          i++;
        }
      } else {
        pixelData = bytes;
      }
      final Uint8List pixelBytes = Uint8List.fromList(pixelData);

      // Step 1: Detect modality
      final modalityResult = _detectModality(pixelBytes);
      debugPrint('[MedicalImageService] Detected: ${modalityResult.$2} '
          '(conf=${modalityResult.$3.toStringAsFixed(2)})');

      // Step 2: Extract local biomarkers
      final biomarkers =
          _extractBiomarkers(pixelBytes, modalityResult.$1, jointType);
      
      // Step 3: Local risk scoring
      final localScore =
          _computeImageRiskScore(biomarkers, modalityResult.$1);
      final findings =
          _generateFindings(biomarkers, modalityResult.$1);
      final interpretation = _generateInterpretation(
          modalityResult.$1, biomarkers, localScore, jointType);

      // Step 4: Server validation (opportunistic)
      bool serverValidated = false;
      Map<String, dynamic>? serverData;
      try {
        serverData = await _uploadToServer(
          imagePath: imagePath,
          modality: modalityResult.$2,
          jointType: jointType,
          localBiomarkers: biomarkers,
        );
        serverValidated = true;
      } catch (e) {
        debugPrint('[MedicalImageService] Server skipped: $e');
      }

      double finalScore = localScore;
      if (serverData != null && serverData['image_risk_score'] != null) {
        final serverScore =
            (serverData['image_risk_score'] as num).toDouble();
        finalScore =
            (localScore * 0.4 + serverScore * 0.6).clamp(0.0, 1.0);
      }

      // Step 5: Enrich existing prediction
      RiskPrediction? enriched;
      if (existingRisk != null) {
        enriched = _enrichPrediction(existingRisk, biomarkers, finalScore);
      }

      return ScanAnalysisResult(
        modality: modalityResult.$1,
        modalityLabel: modalityResult.$2,
        modalityConfidence: modalityResult.$3,
        biomarkers: biomarkers,
        imageRiskScore: finalScore,
        suggestedKLGrade: biomarkers.estimatedKLGrade,
        findings: findings,
        interpretation: interpretation,
        serverValidated: serverValidated,
        enrichedPrediction: enriched,
      );
    } catch (e) {
      debugPrint('[MedicalImageService] Error: $e');
      return _errorResult('Analysis failed: ${e.toString()}');
    }
  }

  // ── Modality Detection ─────────────────────────────────────────────────────

  (ScanModality, String, double) _detectModality(Uint8List bytes) {
    if (bytes.length < 1000) {
      return (ScanModality.unknown, 'Unknown', 0.0);
    }

    final sampleSize = math.min(bytes.length, 50000);
    final step = bytes.length ~/ sampleSize;
    final sample = <int>[];
    for (int i = 0; i < bytes.length; i += math.max(step, 1)) {
      sample.add(bytes[i]);
    }

    final mean =
        sample.fold<double>(0, (s, v) => s + v) / sample.length;
    final variance = sample.fold<double>(
            0, (s, v) => s + math.pow(v - mean, 2).toDouble()) /
        sample.length;
    final stdDev = math.sqrt(variance);

    int dark = 0, mid = 0, bright = 0;
    for (final v in sample) {
      if (v < 86)
        dark++;
      else if (v < 171)
        mid++;
      else
        bright++;
    }
    final total = sample.length;
    final darkRatio = dark / total;
    final midRatio = mid / total;
    final brightRatio = bright / total;

    final bimodalScore = (darkRatio + brightRatio) - midRatio;

    // Entropy
    final hist = List<int>.filled(256, 0);
    for (final v in sample) {
      hist[v]++;
    }
    double entropy = 0;
    for (final count in hist) {
      if (count > 0) {
        final p = count / total;
        entropy -= p * (math.log(p) / math.log(2));
      }
    }

    // USG heuristics: highly speckled, noisy, high entropy but mostly dark/mid-dark tones
    debugPrint('[MedicalImageService Debug] Entropy: $entropy, DarkRatio: $darkRatio, MidRatio: $midRatio, BrightRatio: $brightRatio, StdDev: $stdDev, BimodalScore: $bimodalScore');
    
    if (entropy > 6.0 && darkRatio > 0.40 && midRatio > 0.30 && brightRatio < 0.15 && stdDev < 70) {
      final confidence = math.min(0.90, (entropy / 8.0 * 0.5 + darkRatio * 0.5));
      return (ScanModality.usg, 'Ultrasound', confidence);
    } else if ((bimodalScore > 0.05 && brightRatio > 0.20) || (entropy > 6.5 && brightRatio > 0.30)) {
      // X-Ray: broad histogram, bimodal or just high entropy + lots of bright bone
      final confidence = math.min(0.95, (brightRatio * 0.6 + entropy / 8.0 * 0.4));
      return (ScanModality.xray, 'X-Ray', confidence);
    } else if (entropy > 6.0 && midRatio > 0.50 && stdDev > 60) {
      // MRI: lots of mid-tones (soft tissue), high variance, entropy > 6.0
      final confidence = math.min(0.90, (entropy / 8.0 * 0.7 + midRatio * 0.3));
      return (ScanModality.mri, 'MRI', confidence);
    } else if (midRatio > 0.50 && entropy > 5.0) {
      // CT
      final confidence = math.min(0.85, (midRatio * 0.6 + entropy / 8.0 * 0.4));
      return (ScanModality.ct, 'CT Scan', confidence);
    } else {
      return (ScanModality.xray, 'X-Ray (estimated)', 0.50);
    }
  }

  // ── Biomarker Extraction ───────────────────────────────────────────────────

  ScanBiomarkers _extractBiomarkers(
      Uint8List bytes, ScanModality modality, String jointType) {
    final sampleSize = math.min(bytes.length, 100000);
    final step = math.max(bytes.length ~/ sampleSize, 1);
    final sample = <int>[];
    for (int i = 0; i < bytes.length; i += step) {
      sample.add(bytes[i]);
    }

    final mean =
        sample.fold<double>(0, (s, v) => s + v) / sample.length;
    final variance = sample.fold<double>(
            0, (s, v) => s + math.pow(v - mean, 2).toDouble()) /
        sample.length;
    final stdDev = math.sqrt(variance);

    // Joint space proxy
    double jointSpaceProxy;
    switch (modality) {
      case ScanModality.xray:
        final count = sample.where((v) => v >= 40 && v <= 130).length;
        jointSpaceProxy = (count / sample.length * 2.5).clamp(0.0, 1.0);
        break;
      case ScanModality.mri:
        final count = sample.where((v) => v >= 100 && v <= 200).length;
        jointSpaceProxy = (count / sample.length * 2.0).clamp(0.0, 1.0);
        break;
      case ScanModality.ct:
      case ScanModality.usg:
        final count = sample.where((v) => v >= 60 && v <= 160).length;
        jointSpaceProxy = (count / sample.length * 2.0).clamp(0.0, 1.0);
        break;
      case ScanModality.unknown:
        jointSpaceProxy = 0.5;
    }

    // Edge density (osteophyte proxy)
    double edgeDensity = 0;
    if (sample.length > 10) {
      int edgeCount = 0;
      for (int i = 1; i < sample.length - 1; i++) {
        final grad = (sample[i + 1] - sample[i - 1]).abs();
        if (grad > 40) edgeCount++;
      }
      edgeDensity = edgeCount / sample.length;
    }
    final osteophyteScore = (edgeDensity * 3.5).clamp(0.0, 1.0);

    // Sclerosis / bone density
    final veryBrightCount = sample.where((v) => v > 200).length;
    final sclerosisScore = modality == ScanModality.xray
        ? (veryBrightCount / sample.length * 3.0).clamp(0.0, 1.0)
        : (veryBrightCount / sample.length * 2.0).clamp(0.0, 1.0);

    // Cartilage integrity
    double cartilageIntegrity;
    if (modality == ScanModality.mri) {
      final cartilageCount =
          sample.where((v) => v >= 140 && v <= 220).length;
      cartilageIntegrity =
          (cartilageCount / sample.length * 3.5).clamp(0.0, 1.0);
    } else {
      cartilageIntegrity = jointSpaceProxy * 0.85;
    }

    // Effusion / Inflammation proxy
    double effusionScore = 0.0;
    if (modality == ScanModality.usg || modality == ScanModality.mri) {
      final darkPocketCount = sample.where((v) => v < 30).length;
      effusionScore = (darkPocketCount / sample.length * 4.0).clamp(0.0, 1.0);
    }

    // Image quality
    final dynamicRange = sample.isNotEmpty
        ? sample.reduce(math.max).toDouble() -
            sample.reduce(math.min).toDouble()
        : 0.0;
    final imageQuality =
        ((stdDev / 80.0) * 0.5 + (dynamicRange / 255.0) * 0.5)
            .clamp(0.0, 1.0);

    // KL Grade estimate
    double klScore = 0.0;
    klScore += (1.0 - jointSpaceProxy) * 2.0;
    klScore += osteophyteScore * 1.5;
    klScore += sclerosisScore * 1.0;
    klScore += (1.0 - cartilageIntegrity) * 1.5;

    final estimatedKL = klScore >= 5.0
        ? 4
        : klScore >= 3.5
            ? 3
            : klScore >= 2.0
                ? 2
                : klScore >= 0.8
                    ? 1
                    : 0;

    return ScanBiomarkers(
      estimatedKLGrade: estimatedKL,
      jointSpaceProxy: jointSpaceProxy,
      osteophyteScore: osteophyteScore,
      sclerosisScore: sclerosisScore,
      cartilageIntegrity: cartilageIntegrity,
      effusionScore: effusionScore,
      imageQuality: imageQuality,
    );
  }

  // ── Risk Scoring ───────────────────────────────────────────────────────────

  double _computeImageRiskScore(
      ScanBiomarkers b, ScanModality modality) {
    double score = 0.0;
    score += b.estimatedKLGrade / 4.0 * 0.40;
    score += (1.0 - b.jointSpaceProxy) * 0.20;
    score += b.osteophyteScore * 0.20;
    score += b.sclerosisScore * 0.10;
    
    if (modality == ScanModality.mri) {
      score += (1.0 - b.cartilageIntegrity) * 0.10;
    } else if (modality == ScanModality.usg) {
      score += b.effusionScore * 0.10;
    } else {
      score += (1.0 - b.cartilageIntegrity) * 0.05;
    }
    return score.clamp(0.0, 1.0);
  }

  // ── Findings ───────────────────────────────────────────────────────────────

  List<String> _generateFindings(
      ScanBiomarkers b, ScanModality modality) {
    final findings = <String>[];

    switch (modality) {
      case ScanModality.xray:
        findings.add('X-Ray analysis performed — weight-bearing view assumed');
        break;
      case ScanModality.mri:
        findings.add('MRI analysis performed — soft-tissue detail available');
        break;
      case ScanModality.ct:
        findings.add('CT scan analysis performed — bony detail examined');
        break;
      case ScanModality.usg:
        findings.add('Ultrasound (USG) analysis performed — assessing fluid and synovial inflammation');
        break;
      case ScanModality.unknown:
        findings.add('Scan type estimated — manual verification recommended');
    }

    const klDescriptions = [
      'No radiographic features of OA (KL Grade 0)',
      'Doubtful joint space narrowing, possible osteophytic lipping (KL Grade 1)',
      'Definite osteophytes and possible joint space narrowing (KL Grade 2)',
      'Multiple osteophytes, definite joint space narrowing, some sclerosis (KL Grade 3)',
      'Large osteophytes, marked narrowing, severe sclerosis, bony deformity (KL Grade 4)',
    ];
    findings.add(klDescriptions[b.estimatedKLGrade.clamp(0, 4)]);

    if (b.jointSpaceProxy < 0.30) {
      findings.add('Severe joint space narrowing detected');
    } else if (b.jointSpaceProxy < 0.55) {
      findings.add('Moderate joint space narrowing observed');
    }

    if (b.osteophyteScore > 0.65) {
      findings.add('Prominent osteophyte formation at joint margins');
    } else if (b.osteophyteScore > 0.35) {
      findings.add('Marginal osteophytes present');
    }

    if (modality == ScanModality.mri) {
      if (b.cartilageIntegrity < 0.35) {
        findings.add('Significant cartilage thinning or loss on MRI');
      } else if (b.cartilageIntegrity < 0.60) {
        findings.add('Moderate cartilage signal changes on MRI');
      }
    }

    if (modality == ScanModality.usg || modality == ScanModality.mri) {
      if (b.effusionScore > 0.60) {
        findings.add('Significant joint effusion / synovial inflammation detected');
      } else if (b.effusionScore > 0.30) {
        findings.add('Mild to moderate joint effusion present');
      }
    }

    if (b.imageQuality < 0.40) {
      findings.add('Image quality suboptimal — interpret with caution');
    }

    return findings;
  }

  // ── Interpretation ─────────────────────────────────────────────────────────

  String _generateInterpretation(ScanModality modality,
      ScanBiomarkers b, double riskScore, String joint) {
    final jointName = joint.isNotEmpty ? joint : 'joint';
    final modalityName = modality == ScanModality.xray
        ? 'X-ray'
        : modality == ScanModality.mri
            ? 'MRI'
            : modality == ScanModality.ct
                ? 'CT scan'
                : modality == ScanModality.usg
                    ? 'Ultrasound'
                    : 'scan';
    final severity = b.estimatedKLGrade >= 3
        ? 'severe'
        : b.estimatedKLGrade == 2
            ? 'moderate'
            : b.estimatedKLGrade == 1
                ? 'early'
                : 'no significant';

    final buf = StringBuffer();
    buf.writeln(
        'The uploaded $modalityName of the $jointName demonstrates $severity '
        'radiographic features of osteoarthritis (estimated KL Grade ${b.estimatedKLGrade}/4).');
    buf.writeln();

    switch (modality) {
      case ScanModality.mri:
        buf.writeln(
            'MRI provides excellent soft-tissue resolution for assessing articular '
            'cartilage, synovium, and subchondral bone marrow. Cartilage integrity '
            'is estimated at ${(b.cartilageIntegrity * 100).toStringAsFixed(0)}%.');
        break;
      case ScanModality.xray:
        buf.writeln(
            'Weight-bearing X-ray is the standard imaging modality for OA grading. '
            'Joint space width and osteophyte formation are the primary radiographic indicators.');
        break;
      case ScanModality.ct:
        buf.writeln(
            'CT imaging provides detailed osseous morphology. Bone density, cortical '
            'integrity, and subchondral changes have been assessed.');
        break;
      case ScanModality.usg:
        buf.writeln(
            'Ultrasound is highly effective for detecting joint inflammation, synovial '
            'hypertrophy, and effusion (fluid buildup). '
            '${b.effusionScore > 0.5 ? "Significant inflammation markers observed." : "Minimal effusion noted."}');
        break;
      case ScanModality.unknown:
        buf.writeln('Scan modality could not be reliably determined from image data.');
    }

    return buf.toString();
  }

  // ── Server Upload ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _uploadToServer({
    required String imagePath,
    required String modality,
    required String jointType,
    required ScanBiomarkers localBiomarkers,
  }) async {
    final uri = '${AppConstants.baseUrl}/analyze-scan';

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath),
      'modality': modality,
      'joint_type': jointType,
      'local_biomarkers': jsonEncode(localBiomarkers.toJson()),
    });

    final response = await _dio.post(uri, data: formData);
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Server returned ${response.statusCode}');
  }

  // ── Prediction Enrichment ──────────────────────────────────────────────────

  RiskPrediction _enrichPrediction(
      RiskPrediction existing, ScanBiomarkers b, double imageRiskScore) {
    double existingScore;
    switch (existing.riskLevel) {
      case 'high_risk':
      case 'high':
        existingScore = 0.80;
        break;
      case 'low_risk':
      case 'medium':
        existingScore = 0.50;
        break;
      default:
        existingScore = 0.25;
    }

    final mergedScore =
        (existingScore * 0.60 + imageRiskScore * 0.40).clamp(0.0, 1.0);

    String newRiskLevel;
    double newConfidence;
    if (mergedScore >= 0.60) {
      newRiskLevel = 'high_risk';
      newConfidence =
          (existing.confidence * 0.5 + 0.82 * 0.5).clamp(0.70, 0.96);
    } else if (mergedScore >= 0.30) {
      newRiskLevel = 'low_risk';
      newConfidence =
          (existing.confidence * 0.5 + 0.72 * 0.5).clamp(0.60, 0.88);
    } else {
      newRiskLevel = 'healthy';
      newConfidence =
          (existing.confidence * 0.5 + 0.65 * 0.5).clamp(0.55, 0.80);
    }

    final newFactors = List<String>.from(existing.contributingFactors);
    if (b.estimatedKLGrade >= 2) {
      newFactors.add(
          'Scan shows KL Grade ${b.estimatedKLGrade} joint changes');
    }
    if (b.osteophyteScore > 0.45) {
      newFactors.add('Image-detected osteophyte formation');
    }
    if (b.effusionScore > 0.50) {
      newFactors.add('Image indicates joint effusion/inflammation');
    }

    return RiskPrediction(
      riskLevel: newRiskLevel,
      confidence: newConfidence,
      uncertainty: existing.uncertainty,
      contributingFactors: newFactors,
      reasoning: '${existing.reasoning}\n\n'
          '--- Scan Analysis Update ---\n'
          'Image risk score: ${(imageRiskScore * 100).toStringAsFixed(1)}%. '
          'Risk re-evaluated after integrating radiographic findings.',
    );
  }

  // ── Error helper ───────────────────────────────────────────────────────────

  ScanAnalysisResult _errorResult(String message) {
    return ScanAnalysisResult(
      modality: ScanModality.unknown,
      modalityLabel: 'Unknown',
      modalityConfidence: 0.0,
      biomarkers: const ScanBiomarkers(
        estimatedKLGrade: 0,
        jointSpaceProxy: 0.5,
        osteophyteScore: 0.0,
        sclerosisScore: 0.0,
        cartilageIntegrity: 0.5,
        effusionScore: 0.0,
        imageQuality: 0.0,
      ),
      imageRiskScore: 0.0,
      suggestedKLGrade: 0,
      findings: [message],
      interpretation: message,
    );
  }
}

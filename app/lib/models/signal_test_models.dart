library signal_test_models;

/// Signal and ML Test Dashboard Models
/// Contains data models for the development/testing dashboard
import 'dart:math';
import '../services/tflite_service.dart' as tflite;

/// Signal source type (hardware vs simulated)
enum SignalSourceType {
  hardware,
  simulated,
}

/// ML pipeline stage status
enum PipelineStageStatus {
  idle,
  receiving,
  processing,
  ready,
  error,
}

/// Sensor channel for multi-channel graph
enum SensorChannel {
  accelX,
  accelY,
  accelZ,
  gyroX,
  gyroY,
  gyroZ,
  userAccelX,
  userAccelY,
  userAccelZ,
}

/// Single sensor sample
class SignalSample {
  final DateTime timestamp;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double userAccelX;
  final double userAccelY;
  final double userAccelZ;

  SignalSample({
    required this.timestamp,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.userAccelX,
    required this.userAccelY,
    required this.userAccelZ,
  });

  /// Get value for specific channel
  double getChannelValue(SensorChannel channel) {
    switch (channel) {
      case SensorChannel.accelX:
        return accelX;
      case SensorChannel.accelY:
        return accelY;
      case SensorChannel.accelZ:
        return accelZ;
      case SensorChannel.gyroX:
        return gyroX;
      case SensorChannel.gyroY:
        return gyroY;
      case SensorChannel.gyroZ:
        return gyroZ;
      case SensorChannel.userAccelX:
        return userAccelX;
      case SensorChannel.userAccelY:
        return userAccelY;
      case SensorChannel.userAccelZ:
        return userAccelZ;
    }
  }

  /// Calculate magnitude for accelerometer
  double get accelMagnitude => sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);

  /// Calculate magnitude for gyroscope
  double get gyroMagnitude => sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);

  /// Calculate magnitude for user accelerometer
  double get userAccelMagnitude => sqrt(userAccelX * userAccelX + userAccelY * userAccelY + userAccelZ * userAccelZ);

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'accel_x': accelX,
      'accel_y': accelY,
      'accel_z': accelZ,
      'gyro_x': gyroX,
      'gyro_y': gyroY,
      'gyro_z': gyroZ,
      'user_accel_x': userAccelX,
      'user_accel_y': userAccelY,
      'user_accel_z': userAccelZ,
    };
  }

  factory SignalSample.fromJson(Map<String, dynamic> json) {
    return SignalSample(
      timestamp: DateTime.parse(json['timestamp'] as String),
      accelX: (json['accel_x'] as num).toDouble(),
      accelY: (json['accel_y'] as num).toDouble(),
      accelZ: (json['accel_z'] as num).toDouble(),
      gyroX: (json['gyro_x'] as num).toDouble(),
      gyroY: (json['gyro_y'] as num).toDouble(),
      gyroZ: (json['gyro_z'] as num).toDouble(),
      userAccelX: (json['user_accel_x'] as num).toDouble(),
      userAccelY: (json['user_accel_y'] as num).toDouble(),
      userAccelZ: (json['user_accel_z'] as num).toDouble(),
    );
  }
}

/// Signal source status
class SignalSourceStatus {
  final SignalSourceType sourceType;
  final bool isConnected;
  final String deviceName;
  final bool isSampling;
  final double? samplingRate;
  final DateTime? lastUpdateTime;
  final String? errorMessage;

  SignalSourceStatus({
    required this.sourceType,
    required this.isConnected,
    required this.deviceName,
    required this.isSampling,
    this.samplingRate,
    this.lastUpdateTime,
    this.errorMessage,
  });

  String get statusText {
    if (errorMessage != null) return 'Error: $errorMessage';
    if (!isConnected) return 'Disconnected';
    if (isSampling) return 'Sampling';
    return 'Connected';
  }

  factory SignalSourceStatus.hardware({
    required bool isConnected,
    required String deviceName,
    required bool isSampling,
    double? samplingRate,
    DateTime? lastUpdateTime,
    String? errorMessage,
  }) {
    return SignalSourceStatus(
      sourceType: SignalSourceType.hardware,
      isConnected: isConnected,
      deviceName: deviceName,
      isSampling: isSampling,
      samplingRate: samplingRate,
      lastUpdateTime: lastUpdateTime,
      errorMessage: errorMessage,
    );
  }

  factory SignalSourceStatus.simulated({
    required bool isSampling,
    double? samplingRate,
    DateTime? lastUpdateTime,
    String? errorMessage,
  }) {
    return SignalSourceStatus(
      sourceType: SignalSourceType.simulated,
      isConnected: true, // Simulated is always "connected"
      deviceName: 'Simulated Data',
      isSampling: isSampling,
      samplingRate: samplingRate,
      lastUpdateTime: lastUpdateTime,
      errorMessage: errorMessage,
    );
  }
}

/// Extracted signal features
class SignalFeatures {
  // Accelerometer features
  final double accelMeanX;
  final double accelMeanY;
  final double accelMeanZ;
  final double accelStdX;
  final double accelStdY;
  final double accelStdZ;
  final double accelRms;

  // Gyroscope features
  final double gyroMeanX;
  final double gyroMeanY;
  final double gyroMeanZ;
  final double gyroStdX;
  final double gyroStdY;
  final double gyroStdZ;
  final double gyroRms;

  // User accelerometer features
  final double userAccelMeanX;
  final double userAccelMeanY;
  final double userAccelMeanZ;
  final double userAccelStdX;
  final double userAccelStdY;
  final double userAccelStdZ;

  // Gait features
  final int estimatedSteps;
  final double regularityScore;

  SignalFeatures({
    required this.accelMeanX,
    required this.accelMeanY,
    required this.accelMeanZ,
    required this.accelStdX,
    required this.accelStdY,
    required this.accelStdZ,
    required this.accelRms,
    required this.gyroMeanX,
    required this.gyroMeanY,
    required this.gyroMeanZ,
    required this.gyroStdX,
    required this.gyroStdY,
    required this.gyroStdZ,
    required this.gyroRms,
    required this.userAccelMeanX,
    required this.userAccelMeanY,
    required this.userAccelMeanZ,
    required this.userAccelStdX,
    required this.userAccelStdY,
    required this.userAccelStdZ,
    required this.estimatedSteps,
    required this.regularityScore,
  });

  /// Create from SensorService feature map
  factory SignalFeatures.fromMap(Map<String, dynamic> features) {
    return SignalFeatures(
      accelMeanX: features['accel_mean_x'] ?? 0.0,
      accelMeanY: features['accel_mean_y'] ?? 0.0,
      accelMeanZ: features['accel_mean_z'] ?? 0.0,
      accelStdX: features['accel_std_x'] ?? 0.0,
      accelStdY: features['accel_std_y'] ?? 0.0,
      accelStdZ: features['accel_std_z'] ?? 0.0,
      accelRms: features['accel_rms'] ?? 0.0,
      gyroMeanX: features['gyro_mean_x'] ?? 0.0,
      gyroMeanY: features['gyro_mean_y'] ?? 0.0,
      gyroMeanZ: features['gyro_mean_z'] ?? 0.0,
      gyroStdX: features['gyro_std_x'] ?? 0.0,
      gyroStdY: features['gyro_std_y'] ?? 0.0,
      gyroStdZ: features['gyro_std_z'] ?? 0.0,
      gyroRms: features['gyro_rms'] ?? 0.0,
      userAccelMeanX: features['user_accel_mean_x'] ?? 0.0,
      userAccelMeanY: features['user_accel_mean_y'] ?? 0.0,
      userAccelMeanZ: features['user_accel_mean_z'] ?? 0.0,
      userAccelStdX: features['user_accel_std_x'] ?? 0.0,
      userAccelStdY: features['user_accel_std_y'] ?? 0.0,
      userAccelStdZ: features['user_accel_std_z'] ?? 0.0,
      estimatedSteps: features['estimated_steps'] ?? 0,
      regularityScore: features['regularity_score'] ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accel_mean_x': accelMeanX,
      'accel_mean_y': accelMeanY,
      'accel_mean_z': accelMeanZ,
      'accel_std_x': accelStdX,
      'accel_std_y': accelStdY,
      'accel_std_z': accelStdZ,
      'accel_rms': accelRms,
      'gyro_mean_x': gyroMeanX,
      'gyro_mean_y': gyroMeanY,
      'gyro_mean_z': gyroMeanZ,
      'gyro_std_x': gyroStdX,
      'gyro_std_y': gyroStdY,
      'gyro_std_z': gyroStdZ,
      'gyro_rms': gyroRms,
      'user_accel_mean_x': userAccelMeanX,
      'user_accel_mean_y': userAccelMeanY,
      'user_accel_mean_z': userAccelMeanZ,
      'user_accel_std_x': userAccelStdX,
      'user_accel_std_y': userAccelStdY,
      'user_accel_std_z': userAccelStdZ,
      'estimated_steps': estimatedSteps,
      'regularity_score': regularityScore,
    };
  }
}

/// ML classifier info
class MLClassifierInfo {
  final String modelName;
  final String modelVersion;
  final String inputSource;
  final bool isModelLoaded;
  final String? errorMessage;

  MLClassifierInfo({
    required this.modelName,
    required this.modelVersion,
    required this.inputSource,
    required this.isModelLoaded,
    this.errorMessage,
  });

  factory MLClassifierInfo.tflite({
    required bool isModelLoaded,
    String? errorMessage,
  }) {
    return MLClassifierInfo(
      modelName: 'TFLite OA Risk Classifier',
      modelVersion: 'v1.0',
      inputSource: 'On-device',
      isModelLoaded: isModelLoaded,
      errorMessage: errorMessage,
    );
  }

  factory MLClassifierInfo.backend({
    required bool isModelLoaded,
    String? errorMessage,
  }) {
    return MLClassifierInfo(
      modelName: 'Backend AI Service',
      modelVersion: 'rule_based_v1.0',
      inputSource: 'Backend API',
      isModelLoaded: isModelLoaded,
      errorMessage: errorMessage,
    );
  }
}

/// ML prediction result
class MLPrediction {
  final String riskLevel;
  final double confidence;
  final List<String> contributingFactors;
  final String reasoning;
  final DateTime timestamp;
  final SignalSourceType inputSourceType;
  final int inferenceTimeMs;
  final String modelVersion;

  MLPrediction({
    required this.riskLevel,
    required this.confidence,
    required this.contributingFactors,
    required this.reasoning,
    required this.timestamp,
    required this.inputSourceType,
    required this.inferenceTimeMs,
    required this.modelVersion,
  });

  /// Create from TFLiteService RiskPrediction
  factory MLPrediction.fromTFLite(
    tflite.RiskPrediction prediction,
    SignalSourceType sourceType,
    int inferenceTimeMs,
  ) {
    return MLPrediction(
      riskLevel: prediction.riskLevel,
      confidence: prediction.confidence,
      contributingFactors: prediction.contributingFactors,
      reasoning: prediction.reasoning,
      timestamp: DateTime.now(),
      inputSourceType: sourceType,
      inferenceTimeMs: inferenceTimeMs,
      modelVersion: 'tflite_v1.0',
    );
  }

  /// Create from backend API response
  factory MLPrediction.fromBackend(
    Map<String, dynamic> response,
    SignalSourceType sourceType,
    int inferenceTimeMs,
  ) {
    return MLPrediction(
      riskLevel: response['risk_level'] as String? ?? 'unknown',
      confidence: (response['confidence'] as num?)?.toDouble() ?? 0.0,
      contributingFactors: List<String>.from(response['contributing_factors'] as List? ?? []),
      reasoning: response['reasoning'] as String? ?? '',
      timestamp: DateTime.now(),
      inputSourceType: sourceType,
      inferenceTimeMs: inferenceTimeMs,
      modelVersion: response['model_version'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_level': riskLevel,
      'confidence': confidence,
      'contributing_factors': contributingFactors,
      'reasoning': reasoning,
      'timestamp': timestamp.toIso8601String(),
      'input_source_type': inputSourceType.name,
      'inference_time_ms': inferenceTimeMs,
      'model_version': modelVersion,
    };
  }
}

/// ML pipeline stage
class MLPipelineStage {
  final String name;
  final PipelineStageStatus status;
  final String? errorMessage;

  MLPipelineStage({
    required this.name,
    required this.status,
    this.errorMessage,
  });
}

/// Simulation parameters
class SimulationParameters {
  final double noiseLevel;
  final double frequency;
  final double amplitude;
  final int sampleRate;
  final Duration duration;

  SimulationParameters({
    this.noiseLevel = 0.1,
    this.frequency = 1.0,
    this.amplitude = 1.0,
    this.sampleRate = 50,
    this.duration = const Duration(seconds: 30),
  });

  SimulationParameters copyWith({
    double? noiseLevel,
    double? frequency,
    double? amplitude,
    int? sampleRate,
    Duration? duration,
  }) {
    return SimulationParameters(
      noiseLevel: noiseLevel ?? this.noiseLevel,
      frequency: frequency ?? this.frequency,
      amplitude: amplitude ?? this.amplitude,
      sampleRate: sampleRate ?? this.sampleRate,
      duration: duration ?? this.duration,
    );
  }
}

/// Joint sound/vibration data (placeholder for future implementation)
class JointSoundData {
  final List<double> timeDomain;
  final List<double> frequencyDomain;
  final List<double> frequencies;
  final DateTime timestamp;

  JointSoundData({
    required this.timeDomain,
    required this.frequencyDomain,
    required this.frequencies,
    required this.timestamp,
  });

  /// Indicate if this is simulated data
  bool get isSimulated => true;
}



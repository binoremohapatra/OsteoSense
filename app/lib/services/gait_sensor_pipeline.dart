import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/signal_test_models.dart';
import 'sensor_service.dart';
import 'sensor_data_source.dart';
import 'gait_analyzer.dart';
import 'tflite_service.dart' as tflite;

/// Unified sensor data pipeline for Gait Test
/// Supports both simulated data and hardware (ESP32/Phone sensors)
class GaitSensorPipeline {
  static GaitSensorPipeline? _instance;
  factory GaitSensorPipeline() => _instance ??= GaitSensorPipeline._internal();
  GaitSensorPipeline._internal();

  // Data source
  SignalSourceType _sourceType = SignalSourceType.simulated;
  SensorDataSource? _hardwareSource;
  
  // Data buffers
  final List<SignalSample> _signalBuffer = [];
  static const int _maxBufferSize = 1000; // Keep last 1000 samples
  
  // Real-time sensor data for graphs
  final List<double> _accelX = [];
  final List<double> _accelY = [];
  final List<double> _accelZ = [];
  final List<double> _gyroX = [];
  final List<double> _gyroY = [];
  final List<double> _gyroZ = [];
  final List<double> _piezoData = []; // Joint vibration
  final List<double> _emgData = []; // Muscle activity
  
  static const int _graphBufferSize = 200; // Keep last 200 samples for graphs
  
  // Simulation
  SimulationParameters _simParams = SimulationParameters();
  Timer? _simulationTimer;
  int _simSampleCount = 0;
  
  // Hardware
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;
  
  // Processing
  SignalFeatures? _currentFeatures;
  MLPrediction? _currentPrediction;
  final List<MLPrediction> _predictionHistory = [];
  static const int _maxHistorySize = 20;
  
  // Pipeline status
  final List<PipelineStageStatus> _pipelineStatus = List.generate(
    5, (_) => PipelineStageStatus.idle,
  );
  
  // Callbacks for UI updates
  Function()? onDataUpdate;
  Function()? onFeaturesUpdate;
  Function()? onPredictionUpdate;
  
  // Sampling control
  bool _isRecording = false;
  Duration _recordingDuration = const Duration(seconds: 30);
  
  // Getters
  SignalSourceType get sourceType => _sourceType;
  bool get isRecording => _isRecording;
  List<SignalSample> get signalBuffer => List.from(_signalBuffer);
  SignalFeatures? get currentFeatures => _currentFeatures;
  MLPrediction? get currentPrediction => _currentPrediction;
  List<MLPrediction> get predictionHistory => List.from(_predictionHistory);
  
  // Graph data getters
  List<double> get accelX => List.from(_accelX);
  List<double> get accelY => List.from(_accelY);
  List<double> get accelZ => List.from(_accelZ);
  List<double> get gyroX => List.from(_gyroX);
  List<double> get gyroY => List.from(_gyroY);
  List<double> get gyroZ => List.from(_gyroZ);
  List<double> get piezoData => List.from(_piezoData);
  List<double> get emgData => List.from(_emgData);
  
  // Sensor availability
  bool get hasAccelerometer => _accelX.isNotEmpty;
  bool get hasGyroscope => _gyroX.isNotEmpty;
  bool get hasPiezo => _piezoData.isNotEmpty;
  bool get hasEMG => _emgData.isNotEmpty;
  
  // Pipeline status
  PipelineStageStatus get bleStatus => _pipelineStatus[0];
  PipelineStageStatus get bufferStatus => _pipelineStatus[1];
  PipelineStageStatus get preprocessingStatus => _pipelineStatus[2];
  PipelineStageStatus get featureExtractionStatus => _pipelineStatus[3];
  PipelineStageStatus get mlInferenceStatus => _pipelineStatus[4];
  
  /// Set data source type
  void setSourceType(SignalSourceType type) {
    _sourceType = type;
    _resetPipeline();
  }
  
  /// Set simulation parameters
  void setSimulationParameters(SimulationParameters params) {
    _simParams = params;
  }
  
  /// Set hardware source (ESP32/Phone sensors)
  void setHardwareSource(SensorDataSource? source) {
    _hardwareSource = source;
  }
  
  /// Set UI update callbacks
  void setCallbacks({
    Function()? onDataUpdate,
    Function()? onFeaturesUpdate,
    Function()? onPredictionUpdate,
  }) {
    this.onDataUpdate = onDataUpdate;
    this.onFeaturesUpdate = onFeaturesUpdate;
    this.onPredictionUpdate = onPredictionUpdate;
  }
  
  /// Start recording
  Future<void> startRecording({Duration? duration}) async {
    if (_isRecording) return;
    
    _recordingDuration = duration ?? const Duration(seconds: 30);
    _isRecording = true;
    
    _clearBuffers();
    _updatePipelineStatus(0, PipelineStageStatus.receiving);
    
    if (_sourceType == SignalSourceType.simulated) {
      await _startSimulation();
    } else {
      await _startHardwareRecording();
    }
  }
  
  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    _isRecording = false;
    
    if (_sourceType == SignalSourceType.simulated) {
      _stopSimulation();
    } else {
      await _stopHardwareRecording();
    }
    
    _updatePipelineStatus(0, PipelineStageStatus.ready);
    
    // Extract features from collected data
    await _extractFeatures();
  }
  
  /// Start simulation
  Future<void> _startSimulation() async {
    _simSampleCount = 0;
    _updatePipelineStatus(1, PipelineStageStatus.receiving);
    
    final interval = Duration(milliseconds: (1000 / _simParams.sampleRate).round());
    _simulationTimer = Timer.periodic(interval, (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      if (_simSampleCount >= _recordingDuration!.inSeconds * _simParams.sampleRate) {
        stopRecording();
        return;
      }
      
      _generateSimulatedSample();
      _simSampleCount++;
      
      // Notify UI update (throttled)
      if (_simSampleCount % 5 == 0) {
        onDataUpdate?.call();
      }
    });
  }
  
  /// Stop simulation
  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _updatePipelineStatus(1, PipelineStageStatus.ready);
  }
  
  /// Generate simulated sample
  void _generateSimulatedSample() {
    final now = DateTime.now();
    final t = _simSampleCount / _simParams.sampleRate;
    
    // Generate simulated sensor data with noise
    final noise = (Random().nextDouble() - 0.5) * 2 * _simParams.noiseLevel;
    final signal = _simParams.amplitude * sin(2 * pi * _simParams.frequency * t);
    
    // Walking pattern simulation
    final stepSignal = sin(2 * pi * 1.5 * t); // ~1.5 Hz walking cadence
    
    final sample = SignalSample(
      timestamp: now,
      accelX: signal + noise + stepSignal * 0.5,
      accelY: signal * 0.8 + noise * 0.5 + stepSignal * 0.3,
      accelZ: signal * 0.6 + noise * 0.3 + stepSignal * 0.8, // Vertical component
      gyroX: signal * 0.5 + noise * 0.2,
      gyroY: signal * 0.4 + noise * 0.2,
      gyroZ: signal * 0.3 + noise * 0.1,
      userAccelX: signal * 0.7 + noise * 0.4,
      userAccelY: signal * 0.5 + noise * 0.3,
      userAccelZ: signal * 0.4 + noise * 0.2,
    );
    
    // Simulated piezo (joint vibration)
    final piezoValue = stepSignal * 0.3 + noise * 0.1;
    
    // Simulated EMG (muscle activity)
    final emgValue = (stepSignal.abs() * 0.5) + noise * 0.2;
    
    _addSampleToBuffer(sample, piezoValue, emgValue);
  }
  
  /// Start hardware recording
  Future<void> _startHardwareRecording() async {
    if (_hardwareSource == null) {
      // Fall back to phone sensors
      final sensorService = SensorService();
      sensorService.startRecording(duration: _recordingDuration);
      _updatePipelineStatus(1, PipelineStageStatus.receiving);
      
      // Poll for sensor data
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        
        final accelData = sensorService.accelerometerData;
        final gyroData = sensorService.gyroscopeData;
        final userAccelData = sensorService.userAccelerometerData;
        
        if (accelData.isNotEmpty && gyroData.isNotEmpty) {
          final sampleCount = (accelData.length / 3).floor();
          if (sampleCount > 0) {
            final idx = (sampleCount - 1) * 3;
            final sample = SignalSample(
              timestamp: DateTime.now(),
              accelX: accelData[idx],
              accelY: accelData[idx + 1],
              accelZ: accelData[idx + 2],
              gyroX: gyroData[idx],
              gyroY: gyroData[idx + 1],
              gyroZ: gyroData[idx + 2],
              userAccelX: userAccelData[idx],
              userAccelY: userAccelData[idx + 1],
              userAccelZ: userAccelData[idx + 2],
            );
            
            // No piezo/EMG from phone sensors
            _addSampleToBuffer(sample, 0.0, 0.0);
            
            // Notify UI update (throttled)
            if (sampleCount % 10 == 0) {
              onDataUpdate?.call();
            }
          }
        }
      });
    } else {
      // Use BLE wearable source
      try {
        await _hardwareSource!.initialize();
        await _hardwareSource!.startRecording();
        _updatePipelineStatus(1, PipelineStageStatus.receiving);
        
        // Subscribe to accelerometer
        _accelSubscription = _hardwareSource!.accelerometerStream.listen((data) {
          if (!_isRecording) return;
          
          final sample = SignalSample(
            timestamp: data.timestamp,
            accelX: data.x,
            accelY: data.y,
            accelZ: data.z,
            gyroX: 0, // Will be filled by gyroscope stream
            gyroY: 0,
            gyroZ: 0,
            userAccelX: 0,
            userAccelY: 0,
            userAccelZ: 0,
          );
          
          _addSampleToBuffer(sample, 0.0, 0.0);
          onDataUpdate?.call();
        });
        
        // Subscribe to gyroscope
        _gyroSubscription = _hardwareSource!.gyroscopeStream.listen((data) {
          if (!_isRecording || _signalBuffer.isEmpty) return;
          
          // Update last sample with gyroscope data
          final lastSample = _signalBuffer.last;
          final updatedSample = SignalSample(
            timestamp: lastSample.timestamp,
            accelX: lastSample.accelX,
            accelY: lastSample.accelY,
            accelZ: lastSample.accelZ,
            gyroX: data.x,
            gyroY: data.y,
            gyroZ: data.z,
            userAccelX: lastSample.userAccelX,
            userAccelY: lastSample.userAccelY,
            userAccelZ: lastSample.userAccelZ,
          );
          
          _signalBuffer[_signalBuffer.length - 1] = updatedSample;
          onDataUpdate?.call();
        });
        
      } catch (e) {
        _updatePipelineStatus(0, PipelineStageStatus.error);
        debugPrint('Hardware recording error: $e');
      }
    }
  }
  
  /// Stop hardware recording
  Future<void> _stopHardwareRecording() async {
    if (_hardwareSource != null) {
      await _hardwareSource!.stopRecording();
      await _accelSubscription?.cancel();
      await _gyroSubscription?.cancel();
    } else {
      final sensorService = SensorService();
      sensorService.stopRecording();
    }
    
    _updatePipelineStatus(1, PipelineStageStatus.ready);
  }
  
  /// Add sample to buffer
  void _addSampleToBuffer(SignalSample sample, double piezoValue, double emgValue) {
    _signalBuffer.add(sample);
    if (_signalBuffer.length > _maxBufferSize) {
      _signalBuffer.removeAt(0);
    }
    
    // Update graph buffers
    _accelX.add(sample.accelX);
    _accelY.add(sample.accelY);
    _accelZ.add(sample.accelZ);
    _gyroX.add(sample.gyroX);
    _gyroY.add(sample.gyroY);
    _gyroZ.add(sample.gyroZ);
    _piezoData.add(piezoValue);
    _emgData.add(emgValue);
    
    // Trim graph buffers
    if (_accelX.length > _graphBufferSize) {
      _accelX.removeAt(0);
      _accelY.removeAt(0);
      _accelZ.removeAt(0);
      _gyroX.removeAt(0);
      _gyroY.removeAt(0);
      _gyroZ.removeAt(0);
      _piezoData.removeAt(0);
      _emgData.removeAt(0);
    }
  }
  
  /// Extract features from collected data
  Future<void> _extractFeatures() async {
    if (_signalBuffer.isEmpty) return;
    
    _updatePipelineStatus(2, PipelineStageStatus.processing);
    
    try {
      // Convert signal buffer to format expected by feature extraction
      final accelData = <double>[];
      final gyroData = <double>[];
      final userAccelData = <double>[];
      
      for (final sample in _signalBuffer) {
        accelData.addAll([sample.accelX, sample.accelY, sample.accelZ]);
        gyroData.addAll([sample.gyroX, sample.gyroY, sample.gyroZ]);
        userAccelData.addAll([sample.userAccelX, sample.userAccelY, sample.userAccelZ]);
      }
      
      // Calculate features
      final features = <String, dynamic>{};
      
      // Accelerometer features
      if (accelData.isNotEmpty) {
        final meanX = _calculateMean(_extractAxis(accelData, 0));
        final meanY = _calculateMean(_extractAxis(accelData, 1));
        final meanZ = _calculateMean(_extractAxis(accelData, 2));
        
        features['accel_mean_x'] = meanX;
        features['accel_mean_y'] = meanY;
        features['accel_mean_z'] = meanZ;
        features['accel_rms'] = _calculateRMS(accelData);
        features['accel_std_x'] = _calculateStd(_extractAxis(accelData, 0));
        features['accel_std_y'] = _calculateStd(_extractAxis(accelData, 1));
        features['accel_std_z'] = _calculateStd(_extractAxis(accelData, 2));
      }
      
      // Gyroscope features
      if (gyroData.isNotEmpty) {
        features['gyro_mean_x'] = _calculateMean(_extractAxis(gyroData, 0));
        features['gyro_mean_y'] = _calculateMean(_extractAxis(gyroData, 1));
        features['gyro_mean_z'] = _calculateMean(_extractAxis(gyroData, 2));
        features['gyro_rms'] = _calculateRMS(gyroData);
        features['gyro_std_x'] = _calculateStd(_extractAxis(gyroData, 0));
        features['gyro_std_y'] = _calculateStd(_extractAxis(gyroData, 1));
        features['gyro_std_z'] = _calculateStd(_extractAxis(gyroData, 2));
      }
      
      // User accelerometer features
      if (userAccelData.isNotEmpty) {
        features['user_accel_mean_x'] = _calculateMean(_extractAxis(userAccelData, 0));
        features['user_accel_mean_y'] = _calculateMean(_extractAxis(userAccelData, 1));
        features['user_accel_mean_z'] = _calculateMean(_extractAxis(userAccelData, 2));
        features['user_accel_std_x'] = _calculateStd(_extractAxis(userAccelData, 0));
        features['user_accel_std_y'] = _calculateStd(_extractAxis(userAccelData, 1));
        features['user_accel_std_z'] = _calculateStd(_extractAxis(userAccelData, 2));
      }
      
      // Gait-specific features
      final accelSensorData = _signalBuffer.map((s) => SensorData(
        x: s.userAccelX,
        y: s.userAccelY,
        z: s.userAccelZ,
        timestamp: s.timestamp,
      )).toList();
      
      final gyroSensorData = _signalBuffer.map((s) => SensorData(
        x: s.gyroX,
        y: s.gyroY,
        z: s.gyroZ,
        timestamp: s.timestamp,
      )).toList();
      
      final gaitMetrics = GaitAnalyzer.analyzeGait(
        accelSensorData,
        gyroSensorData,
        _recordingDuration ?? Duration.zero,
      );
      
      features['estimated_steps'] = gaitMetrics.stepsDetected;
      features['regularity_score'] = gaitMetrics.variance;
      features['cadence'] = gaitMetrics.cadence;
      features['stride'] = gaitMetrics.stride;
      features['stability'] = gaitMetrics.stability;
      
      // Piezo features (if available)
      if (_piezoData.isNotEmpty) {
        features['piezo_rms'] = _calculateRMS(_piezoData);
        features['piezo_peak'] = _piezoData.reduce((a, b) => a > b ? a : b);
      }
      
      // EMG features (if available)
      if (_emgData.isNotEmpty) {
        features['emg_rms'] = _calculateRMS(_emgData);
        features['emg_peak'] = _emgData.reduce((a, b) => a > b ? a : b);
        features['emg_mean'] = _calculateMean(_emgData);
      }
      
      _currentFeatures = SignalFeatures.fromMap(features);
      _updatePipelineStatus(2, PipelineStageStatus.ready);
      _updatePipelineStatus(3, PipelineStageStatus.ready);
      
      onFeaturesUpdate?.call();
      
    } catch (e) {
      _updatePipelineStatus(2, PipelineStageStatus.error);
      debugPrint('Feature extraction error: $e');
    }
  }
  
  /// Run ML prediction
  Future<void> runPrediction() async {
    if (_currentFeatures == null) {
      debugPrint('No features available for prediction');
      return;
    }
    
    _updatePipelineStatus(4, PipelineStageStatus.processing);
    
    try {
      final tfliteService = tflite.TFLiteService();
      await tfliteService.loadModel();
      
      // Convert features to feature vector
      final featureVector = [
        _currentFeatures!.accelMeanX,
        _currentFeatures!.accelMeanY,
        _currentFeatures!.accelMeanZ,
        _currentFeatures!.accelStdX,
        _currentFeatures!.accelStdY,
        _currentFeatures!.accelStdZ,
        _currentFeatures!.accelRms,
        _currentFeatures!.gyroMeanX,
        _currentFeatures!.gyroMeanY,
        _currentFeatures!.gyroMeanZ,
        _currentFeatures!.gyroStdX,
        _currentFeatures!.gyroStdY,
        _currentFeatures!.gyroStdZ,
        _currentFeatures!.gyroRms,
        _currentFeatures!.userAccelMeanX,
        _currentFeatures!.userAccelMeanY,
        _currentFeatures!.userAccelMeanZ,
        _currentFeatures!.userAccelStdX,
        _currentFeatures!.userAccelStdY,
        _currentFeatures!.userAccelStdZ,
        _currentFeatures!.estimatedSteps.toDouble(),
        _currentFeatures!.regularityScore,
      ];
      
      final startTime = DateTime.now();
      
      // Run prediction
      final prediction = await tfliteService.predictRisk(
        painLevel: 5, // Default for testing
        stiffnessDuration: '30',
        swelling: false,
        pastInjury: null,
        gaitFeatures: featureVector,
      );
      
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;
      
      final mlPrediction = MLPrediction.fromTFLite(
        prediction,
        _sourceType,
        inferenceTime,
      );
      
      _currentPrediction = mlPrediction;
      _predictionHistory.add(mlPrediction);
      if (_predictionHistory.length > _maxHistorySize) {
        _predictionHistory.removeAt(0);
      }
      
      _updatePipelineStatus(4, PipelineStageStatus.ready);
      onPredictionUpdate?.call();
      
    } catch (e) {
      _updatePipelineStatus(4, PipelineStageStatus.error);
      debugPrint('ML prediction error: $e');
    }
  }
  
  /// Clear all buffers
  void _clearBuffers() {
    _signalBuffer.clear();
    _accelX.clear();
    _accelY.clear();
    _accelZ.clear();
    _gyroX.clear();
    _gyroY.clear();
    _gyroZ.clear();
    _piezoData.clear();
    _emgData.clear();
    _currentFeatures = null;
    _currentPrediction = null;
    _predictionHistory.clear();
  }
  
  /// Reset pipeline status
  void _resetPipeline() {
    for (int i = 0; i < _pipelineStatus.length; i++) {
      _pipelineStatus[i] = PipelineStageStatus.idle;
    }
  }
  
  /// Update pipeline stage status
  void _updatePipelineStatus(int index, PipelineStageStatus status) {
    if (index < 0 || index >= _pipelineStatus.length) return;
    _pipelineStatus[index] = status;
    onDataUpdate?.call();
  }
  
  /// Statistical helpers
  List<double> _extractAxis(List<double> data, int axisIndex) {
    final result = <double>[];
    for (int i = axisIndex; i < data.length; i += 3) {
      result.add(data[i]);
    }
    return result;
  }
  
  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  double _calculateRMS(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sumSquares = values.map((x) => x * x).reduce((a, b) => a + b);
    return sqrt(sumSquares / values.length);
  }
  
  double _calculateStd(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = _calculateMean(values);
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
  
  /// Dispose
  void dispose() {
    _simulationTimer?.cancel();
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _clearBuffers();
    _resetPipeline();
  }
}



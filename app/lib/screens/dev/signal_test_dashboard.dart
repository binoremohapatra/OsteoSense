import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../models/signal_test_models.dart';
import '../../services/sensor_service.dart';
import '../../services/tflite_service.dart';
import '../../services/api_service.dart';
import '../../widgets/premium/cards/premium_cards.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';
import '../../widgets/premium/backgrounds/premium_backgrounds.dart';

/// JointSaathi Signal & ML Test Dashboard
/// Development and testing screen for inspecting sensor data, ML predictions, and signal processing
class SignalTestDashboard extends StatefulWidget {
  const SignalTestDashboard({super.key});

  @override
  State<SignalTestDashboard> createState() => _SignalTestDashboardState();
}

class _SignalTestDashboardState extends State<SignalTestDashboard> {
  // Signal source
  SignalSourceType _sourceType = SignalSourceType.simulated;
  SignalSourceStatus? _sourceStatus;
  
  // Sensor data
  final List<SignalSample> _signalBuffer = [];
  static const int _maxBufferSize = 500; // Last 500 samples
  SensorChannel _selectedChannel = SensorChannel.accelX;
  
  // Simulation
  SimulationParameters _simParams = SimulationParameters();
  Timer? _simulationTimer;
  int _simSampleCount = 0;
  
  // Hardware
  final SensorService _sensorService = SensorService();
  bool _isHardwareRecording = false;
  
  // Features
  SignalFeatures? _currentFeatures;
  
  // ML
  MLClassifierInfo? _classifierInfo;
  MLPrediction? _currentPrediction;
  final List<MLPrediction> _predictionHistory = [];
  static const int _maxHistorySize = 20;
  
  // Pipeline
  final List<MLPipelineStage> _pipelineStages = [
    MLPipelineStage(name: 'Signal', status: PipelineStageStatus.idle),
    MLPipelineStage(name: 'Preprocessing', status: PipelineStageStatus.idle),
    MLPipelineStage(name: 'Feature Extraction', status: PipelineStageStatus.idle),
    MLPipelineStage(name: 'ML Classifier', status: PipelineStageStatus.idle),
    MLPipelineStage(name: 'Prediction', status: PipelineStageStatus.idle),
  ];
  
  // UI state
  bool _showRawData = false;
  bool _showDebugData = false;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    _sensorService.dispose();
    super.dispose();
  }
  
  Future<void> _initializeDashboard() async {
    // Initialize ML classifier info
    setState(() {
      _classifierInfo = MLClassifierInfo.tflite(isModelLoaded: false);
      _sourceStatus = SignalSourceStatus.simulated(isSampling: false);
    });
    
    // Try to load TFLite model
    try {
      final tfliteService = TFLiteService();
      await tfliteService.loadModel();
      setState(() {
        _classifierInfo = MLClassifierInfo.tflite(
          isModelLoaded: tfliteService.isModelLoaded,
        );
      });
    } catch (e) {
      setState(() {
        _classifierInfo = MLClassifierInfo.tflite(
          isModelLoaded: false,
          errorMessage: e.toString(),
        );
      });
    }
  }
  
  void _updatePipelineStage(int index, PipelineStageStatus status, {String? error}) {
    setState(() {
      _pipelineStages[index] = MLPipelineStage(
        name: _pipelineStages[index].name,
        status: status,
        errorMessage: error,
      );
    });
  }
  
  void _resetPipeline() {
    for (int i = 0; i < _pipelineStages.length; i++) {
      _updatePipelineStage(i, PipelineStageStatus.idle);
    }
  }
  
  // Simulation
  void _startSimulation() {
    if (_simulationTimer != null) return;
    
    setState(() {
      _simSampleCount = 0;
      _sourceStatus = SignalSourceStatus.simulated(
        isSampling: true,
        samplingRate: _simParams.sampleRate.toDouble(),
        lastUpdateTime: DateTime.now(),
      );
      _updatePipelineStage(0, PipelineStageStatus.receiving);
    });
    
    final interval = Duration(milliseconds: (1000 / _simParams.sampleRate).round());
    _simulationTimer = Timer.periodic(interval, (timer) {
      if (_simSampleCount >= _simParams.duration.inSeconds * _simParams.sampleRate) {
        _stopSimulation();
        return;
      }
      
      _generateSimulatedSample();
      _simSampleCount++;
      
      setState(() {
        _sourceStatus = SignalSourceStatus.simulated(
          isSampling: true,
          samplingRate: _simParams.sampleRate.toDouble(),
          lastUpdateTime: DateTime.now(),
        );
      });
    });
  }
  
  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    
    setState(() {
      _sourceStatus = SignalSourceStatus.simulated(
        isSampling: false,
        lastUpdateTime: DateTime.now(),
      );
      _updatePipelineStage(0, PipelineStageStatus.ready);
    });
  }
  
  void _generateSimulatedSample() {
    final now = DateTime.now();
    final t = _simSampleCount / _simParams.sampleRate;
    
    // Generate simulated sensor data with noise
    final noise = (Random().nextDouble() - 0.5) * 2 * _simParams.noiseLevel;
    final signal = _simParams.amplitude * sin(2 * pi * _simParams.frequency * t);
    
    final sample = SignalSample(
      timestamp: now,
      accelX: signal + noise,
      accelY: signal * 0.8 + noise * 0.5,
      accelZ: signal * 0.6 + noise * 0.3,
      gyroX: signal * 0.5 + noise * 0.2,
      gyroY: signal * 0.4 + noise * 0.2,
      gyroZ: signal * 0.3 + noise * 0.1,
      userAccelX: signal * 0.7 + noise * 0.4,
      userAccelY: signal * 0.5 + noise * 0.3,
      userAccelZ: signal * 0.4 + noise * 0.2,
    );
    
    _addSampleToBuffer(sample);
  }
  
  // Hardware
  void _startHardwareRecording() {
    if (_isHardwareRecording) return;
    
    setState(() {
      _isHardwareRecording = true;
      _sourceStatus = SignalSourceStatus.hardware(
        isConnected: true,
        deviceName: 'Phone Sensors',
        isSampling: true,
        lastUpdateTime: DateTime.now(),
      );
      _updatePipelineStage(0, PipelineStageStatus.receiving);
    });
    
    _sensorService.startRecording(duration: _simParams.duration);
    
    // Poll for sensor data
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isHardwareRecording) {
        timer.cancel();
        return;
      }
      
      final accelData = _sensorService.accelerometerData;
      final gyroData = _sensorService.gyroscopeData;
      final userAccelData = _sensorService.userAccelerometerData;
      
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
          _addSampleToBuffer(sample);
        }
      }
      
      setState(() {
        _sourceStatus = SignalSourceStatus.hardware(
          isConnected: true,
          deviceName: 'Phone Sensors',
          isSampling: true,
          lastUpdateTime: DateTime.now(),
        );
      });
    });
  }
  
  void _stopHardwareRecording() {
    if (!_isHardwareRecording) return;
    
    _sensorService.stopRecording();
    
    setState(() {
      _isHardwareRecording = false;
      _sourceStatus = SignalSourceStatus.hardware(
        isConnected: true,
        deviceName: 'Phone Sensors',
        isSampling: false,
        lastUpdateTime: DateTime.now(),
      );
      _updatePipelineStage(0, PipelineStageStatus.ready);
    });
  }
  
  void _addSampleToBuffer(SignalSample sample) {
    setState(() {
      _signalBuffer.add(sample);
      if (_signalBuffer.length > _maxBufferSize) {
        _signalBuffer.removeAt(0);
      }
    });
  }
  
  // Feature extraction
  void _extractFeatures() {
    if (_signalBuffer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No signal data available')),
      );
      return;
    }
    
    setState(() {
      _updatePipelineStage(1, PipelineStageStatus.processing);
      _isProcessing = true;
    });
    
    // Use SensorService to extract features
    // Convert signal buffer to format expected by SensorService
    final accelData = <double>[];
    final gyroData = <double>[];
    final userAccelData = <double>[];
    
    for (final sample in _signalBuffer) {
      accelData.addAll([sample.accelX, sample.accelY, sample.accelZ]);
      gyroData.addAll([sample.gyroX, sample.gyroY, sample.gyroZ]);
      userAccelData.addAll([sample.userAccelX, sample.userAccelY, sample.userAccelZ]);
    }
    
    // Temporarily set sensor service data
    // (In production, this would be done differently)
    final features = <String, dynamic>{};
    
    // Calculate basic statistics using index-aware helpers
    List<double> _extractAxis(List<double> data, int axis) {
      final result = <double>[];
      for (int i = axis; i < data.length; i += 3) {
        result.add(data[i]);
      }
      return result;
    }

    if (accelData.isNotEmpty) {
      final ax = _extractAxis(accelData, 0);
      final ay = _extractAxis(accelData, 1);
      final az = _extractAxis(accelData, 2);
      final meanX = ax.reduce((a, b) => a + b) / ax.length;
      final meanY = ay.reduce((a, b) => a + b) / ay.length;
      final meanZ = az.reduce((a, b) => a + b) / az.length;

      features['accel_mean_x'] = meanX;
      features['accel_mean_y'] = meanY;
      features['accel_mean_z'] = meanZ;
      features['accel_rms'] = sqrt(accelData.map((x) => x * x).reduce((a, b) => a + b) / accelData.length);
    }

    if (gyroData.isNotEmpty) {
      final gx = _extractAxis(gyroData, 0);
      final gy = _extractAxis(gyroData, 1);
      final gz = _extractAxis(gyroData, 2);
      features['gyro_mean_x'] = gx.reduce((a, b) => a + b) / gx.length;
      features['gyro_mean_y'] = gy.reduce((a, b) => a + b) / gy.length;
      features['gyro_mean_z'] = gz.reduce((a, b) => a + b) / gz.length;
      features['gyro_rms'] = sqrt(gyroData.map((x) => x * x).reduce((a, b) => a + b) / gyroData.length);
    }

    if (userAccelData.isNotEmpty) {
      final ux = _extractAxis(userAccelData, 0);
      final uy = _extractAxis(userAccelData, 1);
      final uz = _extractAxis(userAccelData, 2);
      features['user_accel_mean_x'] = ux.reduce((a, b) => a + b) / ux.length;
      features['user_accel_mean_y'] = uy.reduce((a, b) => a + b) / uy.length;
      features['user_accel_mean_z'] = uz.reduce((a, b) => a + b) / uz.length;
    }
    
    features['estimated_steps'] = 0; // Would need proper step detection
    features['regularity_score'] = 0.5; // Placeholder
    
    setState(() {
      _currentFeatures = SignalFeatures.fromMap(features);
      _updatePipelineStage(1, PipelineStageStatus.ready);
      _updatePipelineStage(2, PipelineStageStatus.ready);
      _isProcessing = false;
    });
  }
  
  // ML Prediction
  Future<void> _runMLPrediction() async {
    if (_currentFeatures == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please extract features first')),
      );
      return;
    }
    
    setState(() {
      _updatePipelineStage(3, PipelineStageStatus.processing);
      _isProcessing = true;
    });
    
    final startTime = DateTime.now();
    
    try {
      final tfliteService = TFLiteService();
      
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
      
      // Run prediction with rule-based fallback
      final prediction = await tfliteService.predictRisk(
        painLevel: 5, // Default mid-range for testing
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
      
      setState(() {
        _currentPrediction = mlPrediction;
        _predictionHistory.add(mlPrediction);
        if (_predictionHistory.length > _maxHistorySize) {
          _predictionHistory.removeAt(0);
        }
        _updatePipelineStage(3, PipelineStageStatus.ready);
        _updatePipelineStage(4, PipelineStageStatus.ready);
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _updatePipelineStage(3, PipelineStageStatus.error, error: e.toString());
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed: $e')),
      );
    }
  }
  
  void _clearData() {
    setState(() {
      _signalBuffer.clear();
      _currentFeatures = null;
      _currentPrediction = null;
      _predictionHistory.clear();
      _resetPipeline();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Signal & ML Test Dashboard', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showRawData ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showRawData = !_showRawData),
            tooltip: 'Toggle Raw Data',
          ),
          IconButton(
            icon: Icon(_showDebugData ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () => setState(() => _showDebugData = !_showDebugData),
            tooltip: 'Toggle Debug View',
          ),
        ],
      ),
      body: MeshGradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildSourceIndicator(),
            const SizedBox(height: AppSpacing.lg),
            _buildPipelineVisualization(),
            const SizedBox(height: AppSpacing.lg),
            _buildControls(),
            const SizedBox(height: AppSpacing.xl),
            _buildSignalGraph(),
            const SizedBox(height: AppSpacing.xl),
            _buildFeaturesSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildMLClassifierSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildPredictionHistory(),
            const SizedBox(height: AppSpacing.xl),
            if (_showRawData) _buildRawDataInspector(),
            const SizedBox(height: AppSpacing.xl),
            if (_showDebugData) _buildDebugView(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSourceIndicator() {
    final status = _sourceStatus;
    if (status == null) return const SizedBox();
    
    final isSimulated = status.sourceType == SignalSourceType.simulated;
    final statusColor = status.errorMessage != null
        ? AppColors.error
        : status.isSampling
            ? AppColors.success
            : AppColors.textSecondary;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Signal Source',
                style: AppTypography.titleMedium,
              ),
              const Spacer(),
              if (isSimulated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'DEVELOPMENT / SIMULATION',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isSimulated ? '● Simulated Data' : '● Hardware Connected',
            style: AppTypography.bodyLarge.copyWith(
              color: statusColor,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Device: ${status.deviceName}',
            style: AppTypography.bodyMedium,
          ),
          Text(
            'Status: ${status.statusText}',
            style: AppTypography.bodyMedium,
          ),
          if (status.samplingRate != null)
            Text(
              'Sampling Rate: ${status.samplingRate!.toStringAsFixed(1)} Hz',
              style: AppTypography.bodyMedium,
            ),
          if (status.lastUpdateTime != null)
            Text(
              'Last Update: ${_formatTime(status.lastUpdateTime!)}',
              style: AppTypography.caption,
            ),
        ],
      ),
    );
  }
  
  Widget _buildPipelineVisualization() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live ML Pipeline', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _pipelineStages.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              return Expanded(
                child: Column(
                  children: [
                    _buildPipelineStageIcon(stage.status),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      stage.name,
                      style: AppTypography.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                    if (stage.errorMessage != null)
                      Text(
                        'Error',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    if (index < _pipelineStages.length - 1)
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPipelineStageIcon(PipelineStageStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case PipelineStageStatus.idle:
        icon = Icons.circle_outlined;
        color = AppColors.textMuted;
        break;
      case PipelineStageStatus.receiving:
        icon = Icons.radio_button_checked;
        color = AppColors.success;
        break;
      case PipelineStageStatus.processing:
        icon = Icons.refresh;
        color = AppColors.warning;
        break;
      case PipelineStageStatus.ready:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case PipelineStageStatus.error:
        icon = Icons.error;
        color = AppColors.error;
        break;
    }
    
    return Icon(icon, color: color, size: 24);
  }
  
  Widget _buildControls() {
    // Action button callbacks
    final startSimCallback = _simulationTimer == null ? () => _startSimulation() : null;
    final stopSimCallback = _simulationTimer != null ? () => _stopSimulation() : null;
    final startHwCallback = !_isHardwareRecording ? () => _startHardwareRecording() : null;
    final stopHwCallback = _isHardwareRecording ? () => _stopHardwareRecording() : null;
    final extractCallback = _isProcessing ? null : () => _extractFeatures();
    final predictCallback = _isProcessing ? null : () => _runMLPrediction();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Controls', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.md),

        // Source type selector using a simple toggle row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggleChip('Simulated', _sourceType == SignalSourceType.simulated,
                () => setState(() {
                      _sourceType = SignalSourceType.simulated;
                      _clearData();
                    })),
            const SizedBox(width: 8),
            _buildToggleChip('Hardware', _sourceType == SignalSourceType.hardware,
                () => setState(() {
                      _sourceType = SignalSourceType.hardware;
                      _clearData();
                    })),
          ],
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Action buttons

        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (_sourceType == SignalSourceType.simulated) ...[
              GradientButton(
                text: 'Start Simulation',
                gradient: AppColors.primaryGradient,
                onPressed: startSimCallback!,
              ),
              GradientButton(
                text: 'Stop Simulation',
                gradient: AppColors.riskHighGradient,
                onPressed: stopSimCallback!,
              ),
            ] else ...[
              GradientButton(
                text: 'Start Hardware',
                gradient: AppColors.primaryGradient,
                onPressed: startHwCallback!,
              ),
              GradientButton(
                text: 'Stop Hardware',
                gradient: AppColors.riskHighGradient,
                onPressed: stopHwCallback!,
              ),
            ],
            GradientButton(
              text: 'Extract Features',
              gradient: AppColors.sageGradient,
              onPressed: extractCallback!,
            ),
            GradientButton(
              text: 'Run Prediction',
              gradient: AppColors.fullPrimaryGradient,
              onPressed: predictCallback!,
            ),
            GradientButton(
              text: 'Clear',
              gradient: LinearGradient(
                colors: [AppColors.textMuted, AppColors.textSecondary],
              ),
              onPressed: _clearData,
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Simulation parameters (only for simulated mode)
        if (_sourceType == SignalSourceType.simulated)
          _buildSimulationControls(),
      ],
    );
  }

  Widget _buildToggleChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      selected: selected,
      onSelected: (isSelected) {
        if (isSelected) onTap();
      },
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      avatar: selected ? Icon(Icons.check, size: 14) : null,
    );
  }

  Widget _buildSimulationControls() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Simulation Parameters', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Noise Level', style: AppTypography.labelSmall),
                    Slider(
                      value: _simParams.noiseLevel,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() {
                          _simParams = _simParams.copyWith(noiseLevel: value);
                        });
                      },
                    ),
                    Text(_simParams.noiseLevel.toStringAsFixed(2), style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frequency (Hz)', style: AppTypography.labelSmall),
                    Slider(
                      value: _simParams.frequency,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          _simParams = _simParams.copyWith(frequency: value);
                        });
                      },
                    ),
                    Text(_simParams.frequency.toStringAsFixed(1), style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amplitude', style: AppTypography.labelSmall),
                    Slider(
                      value: _simParams.amplitude,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      onChanged: (value) {
                        setState(() {
                          _simParams = _simParams.copyWith(amplitude: value);
                        });
                      },
                    ),
                    Text(_simParams.amplitude.toStringAsFixed(2), style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sample Rate (Hz)', style: AppTypography.labelSmall),
                    Slider(
                      value: _simParams.sampleRate.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          _simParams = _simParams.copyWith(sampleRate: value.toInt());
                        });
                      },
                    ),
                    Text('${_simParams.sampleRate} Hz', style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSignalGraph() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Sensor Signal', style: AppTypography.titleMedium),
              _buildChannelSelector(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: _signalBuffer.isEmpty
                ? Center(
                    child: Text(
                      'No signal data available',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _signalBuffer.asMap().entries.map((entry) {
                            final index = entry.key;
                            final sample = entry.value;
                            return FlSpot(
                              index.toDouble(),
                              sample.getChannelValue(_selectedChannel),
                            );
                          }).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                      minY: -2,
                      maxY: 2,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_signalBuffer.isNotEmpty)
            Row(
              children: [
                Text('Current: ', style: AppTypography.labelSmall),
                Text(
                  _signalBuffer.last.getChannelValue(_selectedChannel).toStringAsFixed(3),
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('Samples: ', style: AppTypography.labelSmall),
                Text(
                  '${_signalBuffer.length}',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildChannelSelector() {
    return Wrap(
      spacing: AppSpacing.xs,
      children: SensorChannel.values.map((channel) {
        final isSelected = channel == _selectedChannel;
        return FilterChip(
          label: Text(
            _getChannelName(channel),
            style: AppTypography.labelSmall,
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedChannel = channel);
            }
          },
          selectedColor: AppColors.primarySurface,
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }
  
  String _getChannelName(SensorChannel channel) {
    switch (channel) {
      case SensorChannel.accelX:
        return 'Acc X';
      case SensorChannel.accelY:
        return 'Acc Y';
      case SensorChannel.accelZ:
        return 'Acc Z';
      case SensorChannel.gyroX:
        return 'Gyro X';
      case SensorChannel.gyroY:
        return 'Gyro Y';
      case SensorChannel.gyroZ:
        return 'Gyro Z';
      case SensorChannel.userAccelX:
        return 'User Acc X';
      case SensorChannel.userAccelY:
        return 'User Acc Y';
      case SensorChannel.userAccelZ:
        return 'User Acc Z';
    }
  }
  
  Widget _buildFeaturesSection() {
    final features = _currentFeatures;
    if (features == null) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Extracted Features', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No features extracted yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Extracted Features', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.5,
            children: [
              _buildFeatureCard('Accel Mean X', features.accelMeanX.toStringAsFixed(3)),
              _buildFeatureCard('Accel Mean Y', features.accelMeanY.toStringAsFixed(3)),
              _buildFeatureCard('Accel Mean Z', features.accelMeanZ.toStringAsFixed(3)),
              _buildFeatureCard('Accel RMS', features.accelRms.toStringAsFixed(3)),
              _buildFeatureCard('Gyro Mean X', features.gyroMeanX.toStringAsFixed(3)),
              _buildFeatureCard('Gyro Mean Y', features.gyroMeanY.toStringAsFixed(3)),
              _buildFeatureCard('Gyro Mean Z', features.gyroMeanZ.toStringAsFixed(3)),
              _buildFeatureCard('Gyro RMS', features.gyroRms.toStringAsFixed(3)),
              _buildFeatureCard('Estimated Steps', features.estimatedSteps.toString()),
              _buildFeatureCard('Regularity Score', features.regularityScore.toStringAsFixed(3)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMLClassifierSection() {
    final classifierInfo = _classifierInfo;
    final prediction = _currentPrediction;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ML Classifier', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          
          if (classifierInfo != null) ...[
            _buildInfoRow('Model', classifierInfo.modelName),
            _buildInfoRow('Version', classifierInfo.modelVersion),
            _buildInfoRow('Input Source', classifierInfo.inputSource),
            _buildInfoRow(
              'Status',
              classifierInfo.isModelLoaded ? 'Loaded' : 'Not Loaded',
              statusColor: classifierInfo.isModelLoaded ? AppColors.success : AppColors.error,
            ),
            if (classifierInfo.errorMessage != null)
              _buildInfoRow('Error', classifierInfo.errorMessage!, statusColor: AppColors.error),
          ],
          
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          
          if (prediction != null) ...[
            _buildPredictionDisplay(prediction),
          ] else ...[
            Text(
              'No prediction yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTypography.labelSmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: statusColor,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPredictionDisplay(MLPrediction prediction) {
    final riskColor = AppColors.getRiskColor(prediction.riskLevel);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Prediction: ', style: AppTypography.labelSmall),
            Text(
              prediction.riskLevel.toUpperCase(),
              style: AppTypography.titleMedium.copyWith(
                color: riskColor,
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildInfoRow('Confidence', '${(prediction.confidence * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Inference Time', '${prediction.inferenceTimeMs} ms'),
        _buildInfoRow('Model Version', prediction.modelVersion),
        _buildInfoRow('Source', prediction.inputSourceType.name.toUpperCase()),
        
        const SizedBox(height: AppSpacing.md),
        
        // Confidence bar
        LinearProgressIndicator(
          value: prediction.confidence,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Contributing factors
        if (prediction.contributingFactors.isNotEmpty) ...[
          Text('Contributing Factors:', style: AppTypography.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          ...prediction.contributingFactors.map((factor) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: AppTypography.bodySmall),
                    Expanded(child: Text(factor, style: AppTypography.bodySmall)),
                  ],
                ),
              )),
        ],
      ],
    );
  }
  
  Widget _buildPredictionHistory() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prediction History', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          
          if (_predictionHistory.isEmpty)
            Text(
              'No predictions yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predictionHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final prediction = _predictionHistory[index];
                final riskColor = AppColors.getRiskColor(prediction.riskLevel);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          _formatTime(prediction.timestamp),
                          style: AppTypography.labelSmall,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          prediction.inputSourceType.name.toUpperCase(),
                          style: AppTypography.labelSmall,
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Text(
                          prediction.riskLevel.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: riskColor,
                            fontWeight: AppTypography.semiBold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${prediction.inferenceTimeMs}ms',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildRawDataInspector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Raw Data Inspector', style: AppTypography.titleMedium),
              TextButton.icon(
                onPressed: () {
                  // Copy JSON
                  if (_signalBuffer.isNotEmpty) {
                    final json = _signalBuffer.last.toJson();
                    // In production, would copy to clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('JSON copied to clipboard')),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy JSON'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (_signalBuffer.isEmpty)
            Text(
              'No data available',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
            Container(
              height: 200,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _signalBuffer.last.toJson().toString(),
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDebugView() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Debug Data', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          
          // Input data
          if (_currentFeatures != null) ...[
            Text('INPUT (Features)', style: AppTypography.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: 150,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _currentFeatures!.toJson().toString(),
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Output data
          if (_currentPrediction != null) ...[
            Text('OUTPUT (Prediction)', style: AppTypography.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: 150,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _currentPrediction!.toJson().toString(),
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

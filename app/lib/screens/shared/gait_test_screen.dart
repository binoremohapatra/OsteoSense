import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../providers/screening_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/patient_provider.dart';
import '../../services/sensor_service.dart';
import '../../services/gait_sensor_pipeline.dart';
import '../../models/signal_test_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/index.dart';
import '../../widgets/premium/cards/premium_cards.dart';
import '../../widgets/premium/loading/premium_loading.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';
import '../../widgets/premium/selection/premium_selection.dart';
import 'processing_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class GaitTestScreen extends StatefulWidget {
  const GaitTestScreen({super.key});

  @override
  State<GaitTestScreen> createState() => _GaitTestScreenState();
}

class _GaitTestScreenState extends State<GaitTestScreen> {
  final SensorService _sensorService = SensorService();
  final GaitSensorPipeline _sensorPipeline = GaitSensorPipeline();
  bool _isRecording = false;
  Timer? _timer;
  int _remainingSeconds = 30;
  final int _totalSeconds = 30;
  
  // Analytics state
  bool _showAnalytics = false;
  SignalSourceType _sourceType = SignalSourceType.simulated;
  SimulationParameters _simParams = SimulationParameters();

  @override
  void initState() {
    super.initState();
    _initializeSensorPipeline();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _sensorService.dispose();
    _sensorPipeline.dispose();
    super.dispose();
  }
  
  void _initializeSensorPipeline() {
    _sensorPipeline.setSourceType(_sourceType);
    _sensorPipeline.setCallbacks(
      onDataUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
      onFeaturesUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
      onPredictionUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _remainingSeconds = _totalSeconds;
      _showAnalytics = true;
    });

    // Start sensor pipeline recording
    _sensorPipeline.setSourceType(_sourceType);
    _sensorPipeline.setSimulationParameters(_simParams);
    _sensorPipeline.startRecording(
      duration: const Duration(seconds: 30),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _stopRecording();
        }
      });
    });
  }

  void _stopRecording() async {
    _timer?.cancel();
    
    // Stop sensor pipeline and extract features
    await _sensorPipeline.stopRecording();
    
    // Run ML prediction if features are available
    if (_sensorPipeline.currentFeatures != null) {
      await _sensorPipeline.runPrediction();
    }

    final screeningProvider = Provider.of<ScreeningProvider>(context, listen: false);
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    
    // Set default values for a gait-only test if not already set
    if (screeningProvider.draftPatientId == null && patientProvider.selectedPatient != null) {
      screeningProvider.draftPatientId = patientProvider.selectedPatient!.id!;
    }
    
    if (screeningProvider.draftPainLevel == 0) {
      screeningProvider.draftPainLevel = 5; // Default moderate pain
    }
    
    if (screeningProvider.draftStiffnessDuration == 'none') {
      screeningProvider.draftStiffnessDuration = '30 minutes';
    }
    
    if (!screeningProvider.draftSwelling) {
      screeningProvider.draftSwelling = true;
    }

    // Get gait features from pipeline
    final features = _sensorPipeline.currentFeatures;
    if (features != null) {
      // Convert features to valid JSON string for storage
      screeningProvider.setDraftGaitData(jsonEncode(features.toJson()));
    } else {
      // Fallback to sensor service
      final gaitFeatures = _sensorService.getFeatureVector();
      screeningProvider.setDraftGaitData(jsonEncode(gaitFeatures));
    }

    setState(() {
      _isRecording = false;
    });

    context.push('/screening/processing');
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);
    final patient = patientProvider.selectedPatient;
    final progress = (_totalSeconds - _remainingSeconds) / _totalSeconds;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Gait Assessment Test',
        centerTitle: true,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/06_gait_test.gif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient info card
              if (patient != null)
                PatientCard(
                  name: patient.name,
                  subtitle: '${patient.age} years',
                  riskLevel: 'medium', // Default for testing context
                  onTap: () {},
                ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: AppSpacing.xl),

              // Instructions card
              CustomCard(
                variant: CardVariant.elevated,
                padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.info,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'How to Perform',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInstructionItem(
                      '1. Stand naturally with your device in your pocket',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInstructionItem(
                      '2. Walk at a normal, comfortable pace',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInstructionItem(
                      '3. Test duration: 30 seconds',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInstructionItem(
                      '4. Walk in a straight line if possible',
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
              const SizedBox(height: AppSpacing.xxxl),

              // Animated Lottie walking figure
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isRecording)
                        PulseLoader(size: 200, color: AppColors.primary.withValues(alpha: 0.2)),
                      if (!_isRecording)
                        Icon(
                          Icons.directions_walk,
                          size: 100,
                          color: AppColors.primary,
                        ).animate()
                         .slideX(begin: -0.2, end: 0.2, duration: 1.seconds)
                         .then()
                         .slideX(begin: 0.2, end: -0.2, duration: 1.seconds)
                      else
                        Icon(
                          Icons.directions_walk,
                          size: 100,
                          color: AppColors.primary,
                        ).animate(target: 1)
                         .slideX(begin: -0.2, end: 0.2, duration: 0.5.seconds)
                         .then()
                         .slideX(begin: 0.2, end: -0.2, duration: 0.5.seconds),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Progress and timer
              if (_isRecording)
                Column(
                  children: [
                    // Circular progress ring with countdown
                    Center(
                      child: CircularProgressRing(
                        value: progress,
                        size: 140,
                        strokeWidth: 8,
                        color: AppColors.primary,
                        label: '$_remainingSeconds"',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Linear progress bar
                    LinearProgressBar(
                      value: progress,
                      height: 6,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Recording in progress...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms)
              else
                MagneticButton(
                  text: 'Start Gait Test',
                  onPressed: _startRecording,
                ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                ),
              if (Navigator.canPop(context)) ...[
                const SizedBox(height: AppSpacing.md),
                GlassButton(
                  text: 'Skip Test',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              
              // Data source selector (for development/testing)
              const SizedBox(height: AppSpacing.xl),
              _buildDataSourceSelector(),
              
              // Analytics sections (shown when recording or after)
              if (_showAnalytics) ...[
                const SizedBox(height: AppSpacing.xl),
                _buildDeviceStatusCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildSensorSummaryCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildLiveSensorGraphs(),
                const SizedBox(height: AppSpacing.lg),
                _buildJointVibrationSection(),
                const SizedBox(height: AppSpacing.lg),
                _buildEMGSection(),
                const SizedBox(height: AppSpacing.lg),
                _buildExtractedFeaturesSection(),
                const SizedBox(height: AppSpacing.lg),
                _buildMLClassifierSection(),
                const SizedBox(height: AppSpacing.lg),
                _buildPipelineVisualization(),
              ],
              
              const SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.primary,
          size: AppSpacing.iconMd,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDataSourceSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_input_antenna,
                color: AppColors.primary,
                size: AppSpacing.iconSm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Data Source',
                style: AppTypography.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedControl<String>(
            segments: const ['Simulated', 'Hardware'],
            currentSegment: _sourceType == SignalSourceType.simulated ? 'Simulated' : 'Hardware',
            onSegmentChanged: (value) {
              setState(() {
                _sourceType = value == 'Simulated' ? SignalSourceType.simulated : SignalSourceType.hardware;
                _sensorPipeline.setSourceType(_sourceType);
              });
            },
            segmentAsString: (v) => v,
          ),
          if (_sourceType == SignalSourceType.simulated) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildSimulationControls(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSimulationControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Simulation Parameters', style: AppTypography.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Noise Level', style: AppTypography.caption),
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
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Frequency (Hz)', style: AppTypography.caption),
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
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDeviceStatusCard() {
    final isSimulated = _sourceType == SignalSourceType.simulated;
    final isConnected = isSimulated || _sensorPipeline.hasAccelerometer;
    
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
                  color: isConnected ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Device Status',
                style: AppTypography.titleSmall,
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    'SIMULATED',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStatusRow('Device', isSimulated ? 'Simulation' : 'ESP32/Phone'),
          _buildStatusRow('Connection', isConnected ? 'Connected' : 'Disconnected'),
          _buildStatusRow('Data Source', isSimulated ? 'Simulated' : 'Hardware'),
          _buildStatusRow('Sampling', _isRecording ? 'Active' : 'Stopped'),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTypography.labelSmall),
          ),
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
  
  Widget _buildSensorSummaryCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sensor Summary', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _buildSensorStatus('Accelerometer', _sensorPipeline.hasAccelerometer),
          _buildSensorStatus('Gyroscope', _sensorPipeline.hasGyroscope),
          _buildSensorStatus('Piezo (Joint Vibration)', _sensorPipeline.hasPiezo, available: false),
          _buildSensorStatus('EMG (Muscle Activity)', _sensorPipeline.hasEMG, available: false),
          _buildSensorStatus('BLE', _sourceType == SignalSourceType.hardware),
        ],
      ),
    );
  }
  
  Widget _buildSensorStatus(String name, bool isActive, {bool available = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isActive ? AppColors.success : (available ? AppColors.textMuted : AppColors.error),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            name,
            style: AppTypography.bodySmall.copyWith(
              color: available ? null : AppColors.textMuted,
            ),
          ),
          if (!available) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              '(Not Available)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLiveSensorGraphs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live Sensor Signals', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.md),
        
        // Accelerometer graph
        _buildSensorGraphCard(
          'Accelerometer',
          _sensorPipeline.accelX,
          _sensorPipeline.accelY,
          _sensorPipeline.accelZ,
          ['X', 'Y', 'Z'],
          [AppColors.primary, AppColors.sage, AppColors.dustyRose],
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Gyroscope graph
        _buildSensorGraphCard(
          'Gyroscope',
          _sensorPipeline.gyroX,
          _sensorPipeline.gyroY,
          _sensorPipeline.gyroZ,
          ['X', 'Y', 'Z'],
          [AppColors.chartSage, AppColors.chartDustyRose, AppColors.chartBeige],
        ),
      ],
    );
  }
  
  Widget _buildSensorGraphCard(
    String title,
    List<double> channel1,
    List<double> channel2,
    List<double> channel3,
    List<String> labels,
    List<Color> colors,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.titleSmall),
              if (_sourceType == SignalSourceType.simulated)
                Text(
                  'SIMULATED',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: channel1.isEmpty
                ? Center(
                    child: Text(
                      _isRecording ? 'Waiting for data...' : 'No data',
                      style: AppTypography.bodySmall.copyWith(
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
                        _buildLineChartData(channel1, colors[0]),
                        _buildLineChartData(channel2, colors[1]),
                        _buildLineChartData(channel3, colors[2]),
                      ],
                      minY: -2,
                      maxY: 2,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? AppSpacing.md : 0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      labels[index],
                      style: AppTypography.caption.copyWith(
                        letterSpacing: 0, // prevent "Z" rendering as "7"
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  LineChartBarData _buildLineChartData(List<double> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value);
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }
  
  Widget _buildJointVibrationSection() {
    return GlassCard(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.vibration, color: AppColors.primary, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.sm),
            Text('Joint Vibration / Piezo', style: AppTypography.titleSmall),
            const Spacer(),
            Text(
              'Not Available',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Center(
            child: Text(
              'Piezo sensor not connected',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }
  
  Widget _buildEMGSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, color: AppColors.primary, size: AppSpacing.iconSm),
              const SizedBox(width: AppSpacing.sm),
              Text('Muscle Activity / EMG', style: AppTypography.titleSmall),
              const Spacer(),
              Text(
                'Not Available',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: Text(
                'EMG sensor not connected',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExtractedFeaturesSection() {
    final features = _sensorPipeline.currentFeatures;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Extracted Features', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          
          if (features == null)
            Text(
              _isRecording ? 'Recording in progress...' : 'No features extracted yet',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
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
    final prediction = _sensorPipeline.currentPrediction;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.primary, size: AppSpacing.iconSm),
              const SizedBox(width: AppSpacing.sm),
              Text('AI / ML Analysis', style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          
          if (prediction == null)
            Text(
              'No prediction yet',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPredictionRow('Model', 'OA Risk Classifier'),
                _buildPredictionRow('Source', _sourceType.name.toUpperCase()),
                _buildPredictionRow('Prediction', prediction.riskLevel.toUpperCase()),
                _buildPredictionRow('Confidence', '${(prediction.confidence * 100).toStringAsFixed(1)}%'),
                _buildPredictionRow('Inference', '${prediction.inferenceTimeMs} ms'),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: prediction.confidence,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.getRiskColor(prediction.riskLevel),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildPredictionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.labelSmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
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
          Text('Signal Processing Pipeline', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPipelineStage('BLE', _sensorPipeline.bleStatus),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                _buildPipelineStage('Buffer', _sensorPipeline.bufferStatus),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                _buildPipelineStage('Process', _sensorPipeline.preprocessingStatus),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                _buildPipelineStage('Features', _sensorPipeline.featureExtractionStatus),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                _buildPipelineStage('ML', _sensorPipeline.mlInferenceStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPipelineStage(String label, PipelineStageStatus status) {
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
    
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

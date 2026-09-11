import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/screening_provider.dart';
import '../../providers/patient_provider.dart';
import '../../services/tflite_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/common/index.dart';
import '../shared/risk_result_screen.dart';
import '../../models/screening.dart';
import '../../models/patient.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  final TFLiteService _tfliteService = TFLiteService();
  late List<ProcessingStep> _steps;
  bool _showSuccess = false;
  late AnimationController _checkmarkController;

  @override
  void initState() {
    super.initState();
    _steps = [
      ProcessingStep(label: 'analyzing_symptoms'.tr(), status: StepStatus.inProgress),
      ProcessingStep(label: 'processing_gait_data'.tr(), status: StepStatus.pending),
      ProcessingStep(label: 'calculating_risk_factors'.tr(), status: StepStatus.pending),
      ProcessingStep(label: 'generating_recommendations'.tr(), status: StepStatus.pending),
    ];
    _checkmarkController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _processScreening();
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _tfliteService.dispose();
    super.dispose();
  }

  Future<void> _processScreening() async {
    await Future.delayed(const Duration(seconds: 2));
    _updateStep(0, StepStatus.completed);

    await Future.delayed(const Duration(seconds: 2));
    _updateStep(1, StepStatus.inProgress);

    await Future.delayed(const Duration(seconds: 2));
    _updateStep(1, StepStatus.completed);
    _updateStep(2, StepStatus.inProgress);

    if (!mounted) return;
    final screeningProvider = Provider.of<ScreeningProvider>(context, listen: false);

    // Ensure we have a patient to run the screening against
    if (screeningProvider.draftPatientId == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Load TFLite model
    await _tfliteService.loadModel();

    // Parse gait features if available
    List<double> gaitFeatures = [];
    if (screeningProvider.draftGaitData != null) {
      try {
        final decoded = jsonDecode(screeningProvider.draftGaitData!);
        if (decoded is Map<String, dynamic>) {
          // Extract numeric values from the features JSON map
          gaitFeatures = decoded.values
              .whereType<num>()
              .map((v) => v.toDouble())
              .toList();
        } else if (decoded is List) {
          gaitFeatures = decoded
              .whereType<num>()
              .map((v) => v.toDouble())
              .toList();
        }
      } catch (e) {
        // Legacy fallback: plain comma-separated string
        try {
          final parsed = screeningProvider.draftGaitData!
              .replaceAll('[', '')
              .replaceAll(']', '')
              .split(',');
          gaitFeatures =
              parsed.map((e) => double.tryParse(e.trim()) ?? 0.0).toList();
        } catch (_) {
          // ignore — gaitFeatures stays empty
        }
      }
    }

    // Run AI prediction
    final prediction = await _tfliteService.predictRisk(
      painLevel: screeningProvider.draftPainLevel,
      stiffnessDuration: screeningProvider.draftStiffnessDuration,
      swelling: screeningProvider.draftSwelling,
      pastInjury: screeningProvider.draftPastInjury ? screeningProvider.draftPastInjuryDetail : null,
      gaitFeatures: gaitFeatures,
    );

    if (!mounted) return;
    _updateStep(2, StepStatus.completed);
    _updateStep(3, StepStatus.inProgress);

    await Future.delayed(const Duration(seconds: 1));
    _updateStep(3, StepStatus.completed);

    // Construct the final screening object first
    final newScreening = Screening(
      patientId: screeningProvider.draftPatientId!,
      userId: 1, // Temporarily hardcoded until auth is integrated
      screeningDate: DateTime.now(),
      jointId: screeningProvider.draftJointId,
      painLevel: screeningProvider.draftPainLevel,
      stiffnessDuration: screeningProvider.draftStiffnessDuration,
      swelling: screeningProvider.draftSwelling,
      pastInjury: screeningProvider.draftPastInjury ? screeningProvider.draftPastInjuryDetail : null,
      gaitData: screeningProvider.draftGaitData,
      riskLevel: prediction.riskLevel,
      confidence: prediction.confidence,
      contributingFactors: prediction.contributingFactors.join(','),
      aiReasoning: prediction.reasoning,
      doctorRecommendations: _generateRecommendations(prediction.riskLevel),
      synced: false,
    );

    // Save screening to database
    final success = await screeningProvider.saveScreening(newScreening);
    
    // Clear draft answers after submission
    screeningProvider.clearDraft();

    if (!mounted) return;

    if (success) {
      // Show success state before navigating
      setState(() => _showSuccess = true);
      await _checkmarkController.forward();
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        // Navigate to report page instead of result page
        final patientProvider = Provider.of<PatientProvider>(context, listen: false);
        final patient = patientProvider.selectedPatient;
        
        if (patient != null) {
          context.push('/screening/report', extra: {
            'screening': screeningProvider.currentScreening ?? newScreening,
            'patient': patient,
          });
        } else {
          // Fallback to result page if no patient
          context.push('/screening/result', extra: screeningProvider.currentScreening ?? newScreening);
        }
      }
    } else {
      // Just navigate back without showing SnackBar to avoid lifecycle issues
      context.pop();
    }
  }

  void _updateStep(int index, StepStatus status) {
    if (mounted) {
      setState(() {
        _steps[index].status = status;
      });
    }
  }

  String _generateRecommendations(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'rec_high'.tr();
      case 'medium':
        return 'rec_medium'.tr();
      case 'low':
      default:
        return 'rec_low'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'processing'.tr(),
        centerTitle: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         kToolbarHeight,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.moderate,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _showSuccess
                  // Delight moment: crisp checkmark before results
                  ? _buildSuccessState()
                  : _buildProcessingState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Padding(
      key: const ValueKey('processing'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Processing animation — the focal point, clean surroundings
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: const Duration(seconds: 2), curve: Curves.easeInOut),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // Heading — minimal, clean
          Column(
            children: [
              Text(
                'analyzing_results'.tr(),
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: AppTypography.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: AppMotion.slow),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'ai_processing_description'.tr(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: AppMotion.slow, delay: 100.ms),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Processing steps
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(
                _steps.length,
                (index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: _buildStepRow(step, index)
                        .animate()
                        .fadeIn(
                          duration: AppMotion.slow,
                          delay: Duration(milliseconds: 100 * (index + 1)),
                        ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text(
            'this_may_take_few_moments'.tr(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(ProcessingStep step, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: step.status == StepStatus.inProgress 
            ? AppColors.primary.withValues(alpha: 0.1)
            : step.status == StepStatus.completed
                ? AppColors.success.withValues(alpha: 0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          // Step indicator — pulse dot for in-progress, not a spinner
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: _buildStepIndicator(step),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              style: AppTypography.bodySmall.copyWith(
                color: step.status == StepStatus.pending
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
                fontWeight: step.status == StepStatus.inProgress
                    ? AppTypography.semiBold
                    : AppTypography.regular,
              ),
              child: Text(
                step.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          if (step.status == StepStatus.completed)
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: AppMotion.fast,
              curve: AppMotion.curvePop,
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ProcessingStep step) {
    switch (step.status) {
      case StepStatus.inProgress:
        // Pulsing teal dot — branded, not generic spinner
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).scaleXY(
          begin: 0.8,
          end: 1.2,
          duration: 800.ms,
          curve: Curves.easeInOut,
        ).animate().fadeIn(duration: AppMotion.fast);

      case StepStatus.completed:
        return Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        );

      case StepStatus.pending:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.gray300,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gray400, width: 1),
          ),
        );
    }
  }

  Widget _buildSuccessState() {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Crisp checkmark animation — draw-on circle + check, 400ms
          Center(
            child: _DrawOnCheckmark(controller: _checkmarkController),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Text(
              'analysis_complete'.tr(),
              style: AppTypography.titleMedium.copyWith(
                fontWeight: AppTypography.semiBold,
                color: AppColors.success,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(duration: AppMotion.slow, delay: 200.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: AppMotion.fast, curve: AppMotion.curvePop),
          const SizedBox(height: AppSpacing.md),
          Text(
            'preparing_results'.tr(),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: AppMotion.slow, delay: 300.ms),
        ],
      ),
    );
  }
}

/// Draw-on checkmark animation — crisp circle outline draws in, then
/// the check appears. 400ms total, purposeful and tasteful (not celebratory).
class _DrawOnCheckmark extends StatelessWidget {
  final AnimationController controller;

  const _DrawOnCheckmark({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final circleProgress = (controller.value * 2).clamp(0.0, 1.0);
        final checkProgress = ((controller.value * 2) - 1).clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            size: const Size(100, 100),
            painter: _CheckmarkPainter(
              circleProgress: circleProgress,
              checkProgress: checkProgress,
              color: AppColors.success,
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw circle outline (draws in from top)
    if (circleProgress > 0) {
      final circlePaint = Paint()
        ..color = color
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // start at top
        2 * 3.14159 * circleProgress,
        false,
        circlePaint,
      );
    }

    // Draw checkmark (appears after circle)
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final p1 = Offset(size.width * 0.25, size.height * 0.5);
      final p2 = Offset(size.width * 0.45, size.height * 0.68);
      final p3 = Offset(size.width * 0.75, size.height * 0.33);

      final path = Path();
      if (checkProgress < 0.5) {
        // Draw from p1 to p2
        final t = checkProgress * 2;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        // Draw full first segment + partial second
        final t = (checkProgress - 0.5) * 2;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * t,
          p2.dy + (p3.dy - p2.dy) * t,
        );
      }
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.circleProgress != circleProgress || old.checkProgress != checkProgress;
}

enum StepStatus {
  pending,
  inProgress,
  completed,
}

class ProcessingStep {
  final String label;
  StepStatus status;

  ProcessingStep({
    required this.label,
    required this.status,
  });
}

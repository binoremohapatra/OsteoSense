import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/common/index.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';
import '../../models/screening.dart';

class RiskResultScreen extends StatefulWidget {
  final Screening? screening;

  const RiskResultScreen({super.key, required this.screening});

  @override
  State<RiskResultScreen> createState() => _RiskResultScreenState();
}

class _RiskResultScreenState extends State<RiskResultScreen> {
  ConfettiController? _confettiController;

  bool get _isLowRisk =>
      (widget.screening?.riskLevel ?? 'low').toLowerCase() == 'low';

  @override
  void initState() {
    super.initState();
    // Confetti is ONLY for a low-risk result — never for medium/high.
    if (_isLowRisk) {
      _confettiController = ConfettiController(duration: AppMotion.ambientLong);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController?.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screening = widget.screening;
    if (screening == null) {
      return Scaffold(
        body: Center(child: Text('no_screening_result_available'.tr())),
      );
    }
    final riskColor = AppColors.getRiskColor(screening.riskLevel ?? 'low');
    final riskLevel = (screening.riskLevel ?? 'low').toLowerCase();

    // Determine target gradient colors based on risk
    final targetColors = riskLevel == 'high'
        ? AppColors.alertGradient.colors
        : riskLevel == 'medium'
            ? AppColors.warningGradient.colors
            : AppColors.successGradient.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(
        title: 'Risk Assessment',
        centerTitle: false,
        showBackButton: true,
      ),
      extendBodyBehindAppBar: true,
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          // Lerp from neutral background to very subtle tinted gradient
          final color1 = Color.lerp(
            AppColors.background,
            targetColors[0].withValues(alpha: 0.08),
            value,
          );
          final color2 = Color.lerp(
            AppColors.background,
            targetColors[1].withValues(alpha: 0.08),
            value,
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color1!, color2!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.22,
                  child: Image.asset(
                    'assets/images/07_risk_result.gif',
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            AmbientBackground(
              primaryColor: riskColor,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Risk Gauge — the emotional centerpiece.
            // Confidence % is shown INSIDE the gauge widget (synced with fill).
            // Breathing glow starts after reveal completes.
            // The gauge handles its own entrance animation internally.
            const SizedBox(height: AppSpacing.sm),
            AnimatedRiskGauge(
              value: (screening.confidence ?? 0.0) * 100,
              riskLevel: _getRiskLevelEnum(screening.riskLevel ?? 'low'),
              confidencePercentage: ((screening.confidence ?? 0.0) * 100).toInt(),
              animate: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Risk level summary — clean card with left accent border
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border(
                  left: BorderSide(color: riskColor, width: 4),
                  top: const BorderSide(color: AppColors.border, width: 1),
                  right: const BorderSide(color: AppColors.border, width: 1),
                  bottom: const BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          _getRiskIcon(screening.riskLevel ?? 'low'),
                          color: riskColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'risk_level'.tr(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              (screening.riskLevel ?? 'low').toUpperCase(),
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: AppTypography.bold,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _getRiskDescription(screening.riskLevel ?? 'low'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: AppMotion.slow, delay: 200.ms),

            const SizedBox(height: AppSpacing.xl),

            // Contributing Factors
            Text(
              'Contributing Factors',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: AppTypography.semiBold,
                letterSpacing: -0.2,
              ),
            ).animate().fadeIn(duration: AppMotion.slow, delay: 280.ms),
            const SizedBox(height: AppSpacing.md),
            _buildFactorsCard(screening).animate().fadeIn(
              duration: AppMotion.slow,
              delay: 320.ms,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recommendations
            Text(
              'Recommendations',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: AppTypography.semiBold,
                letterSpacing: -0.2,
              ),
            ).animate().fadeIn(duration: AppMotion.slow, delay: 380.ms),
            const SizedBox(height: AppSpacing.md),

            CustomCard(
              variant: CardVariant.outlined,
              padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Expert Recommendation',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: AppTypography.semiBold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    // Use AI-returned doctor recommendations if available
                    (screening.doctorRecommendations != null &&
                            screening.doctorRecommendations!.isNotEmpty)
                        ? screening.doctorRecommendations!
                        : _getRecommendation(screening.riskLevel ?? 'low'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: AppMotion.slow, delay: 420.ms),

            // AI Reasoning — show only when AI has provided reasoning
            if (screening.aiReasoning != null &&
                screening.aiReasoning!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'AI Analysis',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: AppTypography.semiBold,
                  letterSpacing: -0.2,
                ),
              ).animate().fadeIn(duration: AppMotion.slow, delay: 460.ms),
              const SizedBox(height: AppSpacing.md),
              CustomCard(
                variant: CardVariant.outlined,
                padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        screening.aiReasoning!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: AppMotion.slow, delay: 480.ms),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    text: 'Back to Home',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MagneticButton(
                    text: 'share_report'.tr(),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('share_feature_coming_soon'.tr())),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: AppMotion.slow, delay: 540.ms),

            const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
              ),
          ),
          // Confetti overlay — ONLY for a low-risk result, never medium/high.
          if (_confettiController != null)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController!,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 18,
                minBlastForce: 6,
                emissionFrequency: 0.08,
                numberOfParticles: 30,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppColors.primary,
                  AppColors.primaryLight,
                  AppColors.accent,
                  AppColors.accentLight,
                  AppColors.riskLow,
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildFactorsCard(Screening screening) {
    // Use AI-returned contributing factors if available (comma-separated string)
    final aiFactors = (screening.contributingFactors ?? '')
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();

    // Fallback: derive factors from raw fields when AI factors are absent
    final fallbackFactors = <String>[
      if ((screening.painLevel ?? 0) >= 5) 'High pain level detected',
      if ((int.tryParse(screening.stiffnessDuration ?? '0') ?? 0) >= 30)
        'Prolonged morning stiffness',
      if (screening.swelling == true) 'Joint swelling observed',
      if (screening.pastInjury != null && screening.pastInjury!.isNotEmpty)
        'History of joint injury',
    ];

    final factors = aiFactors.isNotEmpty ? aiFactors : fallbackFactors;

    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Column(
        children: factors.isEmpty
            ? [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'No significant risk factors detected',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ],
                ),
              ]
            : List.generate(
                factors.length,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index < factors.length - 1 ? AppSpacing.md : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.riskHigh,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          factors[index],
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Icons.warning_amber_outlined;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getRiskDescription(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return 'High OA risk detected. Urgent specialist referral recommended for proper diagnosis and intervention.';
      case 'medium':
        return 'Moderate OA risk. Recommend consultation with a specialist for further evaluation.';
      default:
        return 'Low OA risk. Continue routine health check-ups and maintain healthy lifestyle.';
    }
  }

  String _getRecommendation(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return 'Schedule immediate consultation with an orthopedic specialist. Consider imaging studies (X-ray/MRI).';
      case 'medium':
        return 'Follow up with a healthcare provider. Consider physical therapy and lifestyle modifications.';
      default:
        return 'Maintain regular exercise routine. Focus on joint health and early symptom detection.';
    }
  }

  RiskLevel _getRiskLevelEnum(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      case 'low':
      default:
        return RiskLevel.low;
    }
  }
}
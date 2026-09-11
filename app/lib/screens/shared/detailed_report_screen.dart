import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/screening.dart';
import '../../models/patient.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/common/index.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';
import 'pdf_preview_screen.dart';

class DetailedReportScreen extends StatelessWidget {
  final Screening screening;
  final Patient patient;

  const DetailedReportScreen({
    super.key,
    required this.screening,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = AppColors.getRiskColor(screening.riskLevel ?? 'low');
    final dateStr = DateFormat('d MMM yyyy, h:mm a').format(screening.screeningDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'full_report'.tr(),
        centerTitle: false,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF Preview',
            onPressed: () => context.push('/screening/pdf', extra: {
              'screening': screening,
              'patient': patient,
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/08_detailed_report.gif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Patient header card
            _buildPatientHeaderCard(context, riskColor)
                .animate().fadeIn(duration: AppMotion.standard).slideY(begin: -0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),

            const SizedBox(height: AppSpacing.xl),

            // ── Risk result banner
            _buildRiskBanner(riskColor, dateStr)
                .animate().fadeIn(duration: AppMotion.standard, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),

            const SizedBox(height: AppSpacing.xl),

            // ── Symptom answers
            _buildSectionTitle('symptom_questionnaire'.tr(), Icons.assignment_outlined),
            const SizedBox(height: AppSpacing.md),
            _buildSymptomsCard()
                .animate().fadeIn(duration: AppMotion.standard, delay: 160.ms),

            const SizedBox(height: AppSpacing.xl),

            // ── Gait data
            if (screening.gaitData != null) ...[
              _buildSectionTitle('gait_analysis'.tr(), Icons.directions_walk_rounded),
              const SizedBox(height: AppSpacing.md),
              _buildGaitCard()
                  .animate().fadeIn(duration: AppMotion.standard, delay: 240.ms),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Contributing factors
            _buildSectionTitle('contributing_factors'.tr(), Icons.analytics_outlined),
            const SizedBox(height: AppSpacing.md),
            _buildFactorsCard(riskColor)
                .animate().fadeIn(duration: AppMotion.standard, delay: 320.ms),

            const SizedBox(height: AppSpacing.xl),

            // ── AI Reasoning
            if (screening.aiReasoning != null) ...[
              _buildSectionTitle('ai_clinical_reasoning'.tr(), Icons.psychology_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildReasoningCard()
                  .animate().fadeIn(duration: AppMotion.standard, delay: 400.ms),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Recommendations
            _buildSectionTitle('recommendations'.tr(), Icons.lightbulb_outline),
            const SizedBox(height: AppSpacing.md),
            _buildRecommendationsCard(riskColor)
                .animate().fadeIn(duration: AppMotion.standard, delay: 480.ms),

            const SizedBox(height: AppSpacing.xxl),

            // ── Action buttons
            Row(
              children: [
                Expanded(
                  child: MagneticButton(
                    text: 'share_pdf'.tr(),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PdfPreviewScreen(screening: screening, patient: patient),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: AppMotion.standard, delay: 540.ms),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeaderCard(BuildContext context, Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name, style: AppTypography.titleMedium.copyWith(fontWeight: AppTypography.semiBold)),
                const SizedBox(height: 2),
                Text(
                  '${patient.age} yrs • ${patient.gender.capitalize()} • ${patient.village ?? 'Location not set'}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (screening.jointId != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        screening.jointId!.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (patient.occupation != null) ...[
                  const SizedBox(height: 2),
                  Text(patient.occupation!, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              border: Border.all(color: riskColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              (screening.riskLevel ?? 'low').toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: riskColor,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBanner(Color riskColor, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskColor.withValues(alpha: 0.15), riskColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: riskColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('oa_risk_assessment'.tr(), style: AppTypography.labelSmall.copyWith(color: riskColor.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text(
                  '${(screening.riskLevel ?? 'low').toUpperCase()} RISK',
                  style: AppTypography.headlineSmall.copyWith(color: riskColor, fontWeight: AppTypography.bold),
                ),
                const SizedBox(height: 4),
                if (screening.jointId != null) ...[
                  Text(
                    screening.jointId!.toUpperCase(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(dateStr, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${((screening.confidence ?? 0) * 100).round()}%',
                style: AppTypography.headlineLarge.copyWith(color: riskColor, fontWeight: AppTypography.bold),
              ),
              Text('confidence'.tr(), style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Column(
        children: [
          _answerRow('pain_level'.tr(), '${screening.painLevel ?? 0} / 10', Icons.healing_outlined),
          _divider(),
          _answerRow('morning_stiffness'.tr(), _stiffnessLabel(screening.stiffnessDuration), Icons.schedule_outlined),
          _divider(),
          _answerRow('swelling'.tr(), screening.swelling == true ? 'swelling_present'.tr() : 'no_swelling'.tr(), Icons.water_drop_outlined),
          _divider(),
          _answerRow(
            'past_injury'.tr(),
            screening.pastInjury != null && screening.pastInjury!.isNotEmpty
                ? 'yes'.tr() + ' — ${screening.pastInjury}'
                : 'no_history_of_injury'.tr(),
            Icons.personal_injury_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildGaitCard() {
    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('gait_data_recorded'.tr(), style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
                Text('accelerometer_data'.tr(), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  Widget _buildFactorsCard(Color riskColor) {
    final factors = (screening.contributingFactors ?? '').split('|').where((f) => f.trim().isNotEmpty).toList();

    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: factors.isEmpty
          ? Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.md),
                Text('no_significant_risk_factors'.tr(), style: AppTypography.bodySmall.copyWith(color: AppColors.success)),
              ],
            )
          : Column(
              children: factors.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(bottom: e.key < factors.length - 1 ? AppSpacing.md : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(e.value.trim(), style: AppTypography.bodySmall.copyWith(height: 1.5))),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildReasoningCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text('ai_reasoning'.tr(), style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: AppTypography.semiBold)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            screening.aiReasoning ?? '',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(Color riskColor) {
    final recs = _getRecommendations(screening.riskLevel ?? 'low');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: riskColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: recs.asMap().entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(bottom: e.key < recs.length - 1 ? AppSpacing.md : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: AppTypography.labelSmall.copyWith(color: riskColor, fontWeight: AppTypography.bold),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(e.value, style: AppTypography.bodySmall.copyWith(height: 1.5))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: AppTypography.semiBold)),
      ],
    );
  }

  Widget _answerRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.semiBold)),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Divider(color: AppColors.border, height: 1),
      );

  String _stiffnessLabel(String? val) {
    switch (val) {
      case '<30': return 'less_than_30_minutes'.tr();
      case '30-60': return '30_60_minutes'.tr();
      case '>60': return 'more_than_60_minutes'.tr();
      default: return 'no_stiffness'.tr();
    }
  }

  List<String> _getRecommendations(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return [
          'refer_urgently_orthopedic'.tr(),
          'consider_xray_mri'.tr(),
          'prescribe_analgesics'.tr(),
          'educate_joint_protection'.tr(),
          'schedule_follow_up_2_weeks'.tr(),
        ];
      case 'medium':
        return [
          'consult_physician_1_month'.tr(),
          'physiotherapy_recommended'.tr(),
          'encourage_weight_management'.tr(),
          'prescribe_low_impact_exercise'.tr(),
          'follow_up_screening_3_months'.tr(),
        ];
      default:
        return [
          'maintain_healthy_weight'.tr(),
          'regular_physical_activity'.tr(),
          'healthy_diet'.tr(),
          'adequate_sleep'.tr(),
        ];
    }
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
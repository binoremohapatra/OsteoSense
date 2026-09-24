import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
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

            // ── Advanced ML features
            if (screening.advancedFeaturesVector != null) ...[
              _buildSectionTitle('advanced_ml_features'.tr(), Icons.psychology_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildAdvancedMLCard()
                  .animate().fadeIn(duration: AppMotion.standard, delay: 260.ms),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Contributing factors (only show if data is available from app)
            if (screening.contributingFactors != null && screening.contributingFactors!.isNotEmpty) ...[
              _buildSectionTitle('contributing_factors'.tr(), Icons.analytics_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildFactorsCard(riskColor)
                  .animate().fadeIn(duration: AppMotion.standard, delay: 320.ms),
              const SizedBox(height: AppSpacing.xl),
            ],

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
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GlassButton(
                    text: 'Export ML Data',
                    onPressed: () => _showRawDataDialog(context),
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
              if (screening.mlUncertainty != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Uncertainty: ${(screening.mlUncertainty! * 100).round()}%',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard() {
    // Parse expanded symptoms if available
    Map<String, dynamic> symptomsMap = {};
    if (screening.symptomsMap != null && screening.symptomsMap!.isNotEmpty) {
      try {
        symptomsMap = jsonDecode(screening.symptomsMap!);
      } catch (e) {
        // Keep empty
      }
    }

    // Parse functional assessment if available
    Map<String, dynamic> functionalMap = {};
    if (screening.functionalMap != null && screening.functionalMap!.isNotEmpty) {
      try {
        functionalMap = jsonDecode(screening.functionalMap!);
      } catch (e) {
        // Keep empty
      }
    }

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
          // Show MRI/KL Grade if available
          if (screening.mriKlGrade != null && screening.mriKlGrade! > 0) ...[
            _divider(),
            _answerRow('kl_grade'.tr(), _klGradeLabel(screening.mriKlGrade!), Icons.description_outlined),
          ],
          // Show expanded symptoms if available
          if (symptomsMap.isNotEmpty) ...[
            _divider(),
            _buildExpandedSymptoms(symptomsMap),
          ],
          // Show functional assessment if available
          if (functionalMap.isNotEmpty) ...[
            _divider(),
            _buildFunctionalAssessment(functionalMap),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedSymptoms(Map<String, dynamic> symptomsMap) {
    final items = <Widget>[];
    
    // Pain characteristics
    final painChars = symptomsMap['pain_characteristics'] as Map<String, dynamic>?;
    if (painChars != null) {
      final selected = painChars.entries.where((e) => e.value == true).map((e) => e.key).toList();
      if (selected.isNotEmpty) {
        items.add(_answerRow('pain_characteristics'.tr(), selected.join(', '), Icons.info_outline));
        items.add(_divider());
      }
    }

    // Stiffness triggers
    final stiffnessTriggers = symptomsMap['stiffness_triggers'] as Map<String, dynamic>?;
    if (stiffnessTriggers != null) {
      final selected = stiffnessTriggers.entries.where((e) => e.value == true).map((e) => e.key).toList();
      if (selected.isNotEmpty) {
        items.add(_answerRow('stiffness_triggers'.tr(), selected.join(', '), Icons.info_outline));
        items.add(_divider());
      }
    }

    // Other symptoms
    final otherSymptoms = symptomsMap['other_symptoms'] as Map<String, dynamic>?;
    if (otherSymptoms != null) {
      final selected = otherSymptoms.entries.where((e) => e.value == true).map((e) => e.key).toList();
      if (selected.isNotEmpty) {
        items.add(_answerRow('other_symptoms'.tr(), selected.join(', '), Icons.info_outline));
        items.add(_divider());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text('expanded_symptoms'.tr(), style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
        ),
        ...items,
      ],
    );
  }

  Widget _buildFunctionalAssessment(Map<String, dynamic> functionalMap) {
    final items = <Widget>[];
    
    functionalMap.forEach((key, value) {
      if (value is int && value > 0) {
        final label = _getDifficultyLabel(key, value);
        items.add(_answerRow(key, label, Icons.accessibility_new));
        items.add(_divider());
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text('functional_assessment'.tr(), style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
        ),
        ...items,
      ],
    );
  }

  String _getDifficultyLabel(String key, int value) {
    final labels = {
      0: 'none'.tr(),
      1: 'mild'.tr(),
      2: 'moderate'.tr(),
      3: 'severe'.tr(),
    };
    return '${labels[value] ?? value.toString()} (${value}/3)';
  }

  String _klGradeLabel(int grade) {
    switch (grade) {
      case 1: return 'grade_1_doubtful'.tr();
      case 2: return 'grade_2_mild'.tr();
      case 3: return 'grade_3_moderate'.tr();
      case 4: return 'grade_4_severe'.tr();
      default: return 'normal_none'.tr();
    }
  }

  Widget _buildGaitCard() {
    List<double>? gaitFeats;
    try {
      final decoded = jsonDecode(screening.gaitData!);
      if (decoded is List) {
        gaitFeats = decoded.map((e) => (e as num).toDouble()).toList();
      }
    } catch (e) {
      debugPrint('Error decoding gait data: $e');
    }

    if (gaitFeats == null || gaitFeats.length < 44) {
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

    // Pull out some key metrics
    final cadence = gaitFeats[0];
    final strideTime = gaitFeats[1];
    final piezoDominant = gaitFeats[23];
    final emgRms = gaitFeats[34];

    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Sensor Analytics Data', style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            children: [
              _metricCell('Cadence', cadence > 0 ? '${cadence.toStringAsFixed(1)} Hz' : '--'),
              _metricCell('Stride Time', strideTime > 0 ? '${strideTime.toStringAsFixed(2)} s' : '--'),
              _metricCell('Piezo Dominant Freq', piezoDominant > 0 ? '${piezoDominant.toStringAsFixed(0)} Hz' : '--'),
              _metricCell('Muscle EMG (RMS)', emgRms > 0 ? emgRms.toStringAsFixed(3) : '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
      ],
    );
  }

  Widget _buildAdvancedMLCard() {
    // Parse advanced features vector
    List<double> advancedFeats = [];
    try {
      final decoded = jsonDecode(screening.advancedFeaturesVector!);
      if (decoded is List) {
        advancedFeats = decoded.map((e) => (e as num).toDouble()).toList();
      }
    } catch (e) {
      debugPrint('Error decoding advanced features: $e');
    }

    // Extract key advanced features
    final gaitVariability = screening.gaitVariability ?? 0.0;
    final gaitAsymmetry = screening.gaitAsymmetry ?? 0.0;
    final gaitSmoothness = screening.gaitSmoothness ?? 0.0;
    final posturalStability = screening.posturalStability ?? 0.0;
    final painFrequency = screening.painFrequency ?? 'N/A';
    final activityLimitation = screening.activityLimitation ?? 'N/A';
    final symptomDuration = screening.symptomDuration ?? 'N/A';

    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Advanced ML Features', style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
                    Text('203 features extracted', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (screening.mlUncertainty != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Uncertainty: ${(screening.mlUncertainty! * 100).round()}%',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          
          // Gait Analysis Section
          Text('Gait Analysis', style: AppTypography.labelMedium.copyWith(fontWeight: AppTypography.semiBold)),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            children: [
              _metricCell('Gait Variability', '${gaitVariability.toStringAsFixed(3)}'),
              _metricCell('Gait Asymmetry', '${gaitAsymmetry.toStringAsFixed(3)}'),
              _metricCell('Gait Smoothness', '${gaitSmoothness.toStringAsFixed(3)}'),
              _metricCell('Postural Stability', '${posturalStability.toStringAsFixed(3)}'),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          
          // Clinical Section
          Text('Clinical Factors', style: AppTypography.labelMedium.copyWith(fontWeight: AppTypography.semiBold)),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            children: [
              _metricCell('Pain Frequency', painFrequency),
              _metricCell('Activity Limitation', activityLimitation),
              _metricCell('Symptom Duration', symptomDuration),
              _metricCell('Medication Use', screening.medicationUse == true ? 'Yes' : 'No'),
            ],
          ),
          
          if (advancedFeats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.md),
            Text('Feature Vector Size: ${advancedFeats.length}', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
          ],
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

  void _showRawDataDialog(BuildContext context) {
    List<double> gaitFeats = [];
    try {
      final decoded = jsonDecode(screening.gaitData!);
      if (decoded is List) {
        gaitFeats = decoded.map((e) => (e as num).toDouble()).toList();
      }
    } catch (e) {
      debugPrint('Error decoding gait data: $e');
    }

    // Assemble advanced 203-feature ML input vector
    // Symptoms
    final stiffnessVal = int.tryParse(screening.stiffnessDuration ?? '0') ?? 0;
    final painLevel = (screening.painLevel ?? 0).toDouble();
    final stiffnessDuration = stiffnessVal.toDouble();
    final swelling = screening.swelling == true ? 1.0 : 0.0;
    final pastInjury = (screening.pastInjury != null && screening.pastInjury!.isNotEmpty) ? 1.0 : 0.0;
    final mriKlGrade = (screening.mriKlGrade ?? 0).toDouble();

    // Advanced clinical features
    final painFrequency = _encodePainFrequency(screening.painFrequency);
    final activityLimitation = _encodeActivityLimitation(screening.activityLimitation);
    final medicationUse = screening.medicationUse == true ? 1.0 : 0.0;
    final symptomDuration = _encodeSymptomDuration(screening.symptomDuration);

    // Demographics
    final age = patient.age.toDouble();
    final weightKg = patient.weightKg ?? 70.0;
    final heightCm = patient.heightCm ?? 170.0;
    double bmi = 0.0;
    if (heightCm > 0) {
      final heightM = heightCm / 100.0;
      bmi = weightKg / (heightM * heightM);
    }

    // Advanced gait features
    final gaitVariability = screening.gaitVariability ?? 0.1;
    final gaitAsymmetry = screening.gaitAsymmetry ?? 0.05;
    final gaitSmoothness = screening.gaitSmoothness ?? 0.9;
    final posturalStability = screening.posturalStability ?? 0.8;

    // Use advanced features vector if available, otherwise build from components
    List<double> mlVector;
    if (screening.advancedFeaturesVector != null) {
      try {
        final decoded = jsonDecode(screening.advancedFeaturesVector!);
        if (decoded is List) {
          mlVector = decoded.map((e) => (e as num).toDouble()).toList();
        } else {
          mlVector = _buildAdvancedFeatureVector(gaitFeats, painLevel, stiffnessDuration, swelling, pastInjury, mriKlGrade, age, weightKg, heightCm, bmi, painFrequency, activityLimitation, medicationUse, symptomDuration, gaitVariability, gaitAsymmetry, gaitSmoothness, posturalStability);
        }
      } catch (e) {
        mlVector = _buildAdvancedFeatureVector(gaitFeats, painLevel, stiffnessDuration, swelling, pastInjury, mriKlGrade, age, weightKg, heightCm, bmi, painFrequency, activityLimitation, medicationUse, symptomDuration, gaitVariability, gaitAsymmetry, gaitSmoothness, posturalStability);
      }
    } else {
      mlVector = _buildAdvancedFeatureVector(gaitFeats, painLevel, stiffnessDuration, swelling, pastInjury, mriKlGrade, age, weightKg, heightCm, bmi, painFrequency, activityLimitation, medicationUse, symptomDuration, gaitVariability, gaitAsymmetry, gaitSmoothness, posturalStability);
    }
    
    final riskLabel = screening.riskLevel ?? 'low';
    final resultJson = jsonEncode({
      'features_203': mlVector,
      'risk_label': riskLabel,
      'confidence': screening.confidence,
      'uncertainty': screening.mlUncertainty,
      'model_type': 'advanced_ensemble',
      'feature_breakdown': {
        'gait_features': gaitFeats.length,
        'clinical_features': 8,
        'demographic_features': 4,
        'advanced_gait_features': 4,
        'total_features': mlVector.length
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Advanced ML Training Data', style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Copy this JSON to train the Advanced ML model (${mlVector.length} features):', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                color: AppColors.background,
                child: SelectableText(resultJson, style: AppTypography.caption),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Model: Advanced Ensemble (3 models)', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
              if (screening.mlUncertainty != null)
                Text('Uncertainty: ${(screening.mlUncertainty! * 100).round()}%', style: AppTypography.labelSmall.copyWith(color: AppColors.warning)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  List<double> _buildAdvancedFeatureVector(
    List<double> gaitFeats,
    double painLevel,
    double stiffnessDuration,
    double swelling,
    double pastInjury,
    double mriKlGrade,
    double age,
    double weightKg,
    double heightCm,
    double bmi,
    double painFrequency,
    double activityLimitation,
    double medicationUse,
    double symptomDuration,
    double gaitVariability,
    double gaitAsymmetry,
    double gaitSmoothness,
    double posturalStability,
  ) {
    // Build 203-feature vector based on advanced feature extraction
    // This is a simplified version - actual extraction would be done by the advanced model
    List<double> vector = [];
    
    // Add gait features (pad to expected size)
    while (gaitFeats.length < 180) {
      gaitFeats.add(0.0);
    }
    vector.addAll(gaitFeats.sublist(0, 180));
    
    // Add clinical features
    vector.addAll([
      painLevel,
      stiffnessDuration,
      swelling,
      pastInjury,
      mriKlGrade,
      painFrequency,
      activityLimitation,
      medicationUse,
      symptomDuration,
    ]);
    
    // Add demographic features
    vector.addAll([age, weightKg, heightCm, bmi]);
    
    // Add advanced gait features
    vector.addAll([gaitVariability, gaitAsymmetry, gaitSmoothness, posturalStability]);
    
    // Pad to 203 features
    while (vector.length < 203) {
      vector.add(0.0);
    }
    
    return vector.sublist(0, 203);
  }

  double _encodePainFrequency(String? frequency) {
    if (frequency == null) return 0.0;
    switch (frequency.toLowerCase()) {
      case 'never': return 0.0;
      case 'weekly': return 1.0;
      case 'daily': return 2.0;
      default: return 0.0;
    }
  }

  double _encodeActivityLimitation(String? limitation) {
    if (limitation == null) return 0.0;
    switch (limitation.toLowerCase()) {
      case 'none': return 0.0;
      case 'mild': return 1.0;
      case 'moderate': return 2.0;
      case 'severe': return 3.0;
      default: return 0.0;
    }
  }

  double _encodeSymptomDuration(String? duration) {
    if (duration == null) return 0.0;
    switch (duration.toLowerCase()) {
      case 'none': return 0.0;
      case '<1_month': return 1.0;
      case '1-3_months': return 2.0;
      case '3-6_months': return 3.0;
      case '6-12_months': return 4.0;
      case '1-2_years': return 5.0;
      case '>2_years': return 6.0;
      default: return 0.0;
    }
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
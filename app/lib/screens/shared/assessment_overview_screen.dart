import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/screening_provider.dart';
import '../../services/database_helper.dart';
import '../../models/medical_history.dart';
import '../../models/surgery_history.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';

class AssessmentOverviewScreen extends StatelessWidget {
  const AssessmentOverviewScreen({super.key});

  void _proceed(BuildContext context) {
    HapticFeedback.mediumImpact();
    // Navigate to gait test
    context.push('/screening/gait');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScreeningProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'symptom_assessment'.tr(),
        centerTitle: false,
        showBackButton: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([
          DatabaseHelper().query('medical_history', where: 'patient_id = ?', whereArgs: [provider.draftPatientId], orderBy: 'created_at DESC', limit: 1),
          DatabaseHelper().query('surgery_history', where: 'patient_id = ?', whereArgs: [provider.draftPatientId], orderBy: 'created_at DESC', limit: 1),
        ]),
        builder: (context, AsyncSnapshot<List<List<Map<String, dynamic>>>> snapshot) {
          MedicalHistory? medHistory;
          SurgeryHistory? surHistory;
          
          if (snapshot.hasData) {
            if (snapshot.data![0].isNotEmpty) {
              medHistory = MedicalHistory.fromMap(snapshot.data![0].first);
            }
            if (snapshot.data![1].isNotEmpty) {
              surHistory = SurgeryHistory.fromMap(snapshot.data![1].first);
            }
          }
          
          return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/05_joint_selection.gif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Title 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                            ),
                            child: Text(
                              'Overview',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: AppTypography.semiBold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Review Assessment',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: AppTypography.semiBold,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Please review all selections before starting the gait test.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: AppMotion.standard).slideY(begin: -0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),
                      
                      const SizedBox(height: AppSpacing.xxl),

                      // Summary card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.summarize_outlined, color: AppColors.primary, size: 18),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'your_answers_so_far'.tr(),
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: AppTypography.semiBold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            
                            _summaryRow('Joint', provider.draftJointId ?? 'Not selected'),
                            _summaryRow('Side', provider.draftSide ?? 'Not selected'),
                            _summaryRow('pain_level'.tr(), '${provider.draftPainLevel} / 10'),
                            _summaryRow('morning_stiffness'.tr(), provider.draftStiffnessDuration),
                            _summaryRow('swelling'.tr(), provider.draftSwelling ? 'yes'.tr() : 'no'.tr()),
                            _summaryRow('past_injury'.tr(), provider.draftPastInjury ? 'yes'.tr() : 'no'.tr()),
                            
                            if (provider.draftSymptomsMap.isNotEmpty) ...[
                              const Divider(height: AppSpacing.xl),
                              _summaryRow('Symptoms', _getMapKeys(provider.draftSymptomsMap['pain_characteristics'])),
                              _summaryRow('Triggers', _getMapKeys(provider.draftSymptomsMap['stiffness_triggers'])),
                            ],
                            
                            if (medHistory != null) ...[
                              const Divider(height: AppSpacing.xl),
                              _summaryRow('Prev. Diagnosis', medHistory.previousDiagnosis == true ? 'yes'.tr() : 'no'.tr()),
                              _summaryRow('Prev. Joint Pain', medHistory.previousJointPain == true ? 'yes'.tr() : 'no'.tr()),
                              _summaryRow('Chronic Joint Prob.', medHistory.chronicJointProblems == true ? 'yes'.tr() : 'no'.tr()),
                              _summaryRow('Past Inflammation', medHistory.previousInflammation == true ? 'yes'.tr() : 'no'.tr()),
                              _summaryRow('Cartilage Prob.', medHistory.previousCartilageProblems == true ? 'yes'.tr() : 'no'.tr()),
                              _summaryRow('Ligament Prob.', medHistory.previousLigamentProblems == true ? 'yes'.tr() : 'no'.tr()),
                              _summaryRow('Past Fracture', medHistory.previousFracture == true ? 'yes'.tr() : 'no'.tr()),
                              _summaryRow('Past Injury', medHistory.hasPastInjury == true ? 'yes'.tr() : 'no'.tr()),
                              if (medHistory.hasPastInjury == true) ...[
                                _summaryRow('Injury Type', medHistory.injuryType ?? 'N/A'),
                                _summaryRow('Severity', medHistory.injurySeverity ?? 'N/A'),
                                _summaryRow('Mechanism', medHistory.injuryMechanism ?? 'N/A'),
                                _summaryRow('Med. Treatment', medHistory.medicalTreatmentRequired == true ? 'yes'.tr() : 'no'.tr()),
                                _summaryRow('Immobilization', medHistory.immobilizationRequired == true ? 'yes'.tr() : 'no'.tr()),
                                _summaryRow('Physiotherapy', medHistory.physiotherapyPerformed == true ? 'yes'.tr() : 'no'.tr()),
                                _summaryRow('Current Symptoms', medHistory.currentSymptomsAfterInjury ?? 'N/A'),
                              ]
                            ],
                            
                            if (surHistory != null) ...[
                              const Divider(height: AppSpacing.xl),
                              _summaryRow('Past Surgery', 'yes'.tr()),
                              _summaryRow('Surgery Type', surHistory.surgeryType),
                              if (surHistory.surgeryDate != null)
                                _summaryRow('Surgery Date', surHistory.surgeryDate!),
                              if (surHistory.reason != null)
                                _summaryRow('Reason', surHistory.reason!),
                              _summaryRow('Implant Present', surHistory.implantPresent == true ? 'yes'.tr() : 'no'.tr()),
                            ],
                            
                            if (provider.draftFunctionalMap.isNotEmpty) ...[
                              const Divider(height: AppSpacing.xl),
                              ...provider.draftFunctionalMap.entries.map((e) => _summaryRow(e.key, '${e.value}/3')),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: AppMotion.standard, delay: 200.ms),
                    ],
                  ),
                ),
              ),

              // Bottom Button Bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, size: 20),
                        label: Text('back'.tr()),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: MagneticButton(
                        text: 'Start Gait Test',
                        onPressed: () => _proceed(context),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: AppMotion.standard).slideY(begin: 0.2, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),
            ],
          ),
        ],
      );
    }
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMapKeys(dynamic mapData) {
    if (mapData == null || mapData is! Map) return '';
    final selected = mapData.entries.where((e) => e.value == true).map((e) => e.key.toString()).toList();
    return selected.join(', ');
  }
}

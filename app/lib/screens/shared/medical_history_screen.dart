import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/screening_provider.dart';
import '../../providers/patient_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final int patientId;
  final String jointId;
  final String side;

  const MedicalHistoryScreen({
    super.key,
    required this.patientId,
    required this.jointId,
    required this.side,
  });

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  bool _previousDiagnosis = false;
  bool _previousJointPain = false;
  bool _chronicJointProblems = false;
  bool _previousInflammation = false;
  bool _hasPastInjury = false;

  void _proceed() {
    HapticFeedback.mediumImpact();
    
    // In a real app we'd save this to a MedicalHistory object in a provider or DB
    // For now we just push the next screen. We will push to surgery history.
    context.push('/screening/surgery_history', extra: {
      'patientId': widget.patientId,
      'jointId': widget.jointId,
      'side': widget.side,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'medical_history'.tr(),
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'past_medical_history'.tr(),
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${'for_side_joint'.tr().replaceAll('{side}', widget.side).replaceAll('{joint}', widget.jointId)}',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    _buildSwitchTile(
                      'previous_diagnosis_of_arthritis'.tr(),
                      _previousDiagnosis,
                      (val) => setState(() => _previousDiagnosis = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildSwitchTile(
                      'previous_joint_pain_episodes'.tr(),
                      _previousJointPain,
                      (val) => setState(() => _previousJointPain = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildSwitchTile(
                      'chronic_joint_problems'.tr(),
                      _chronicJointProblems,
                      (val) => setState(() => _chronicJointProblems = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildSwitchTile(
                      'previous_joint_inflammation_swelling'.tr(),
                      _previousInflammation,
                      (val) => setState(() => _previousInflammation = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildSwitchTile(
                      'history_of_injury_to_this_joint'.tr(),
                      _hasPastInjury,
                      (val) => setState(() => _hasPastInjury = val),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: MagneticButton(
                text: 'next'.tr(),
                onPressed: _proceed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: SwitchListTile(
            title: Text(title, style: AppTypography.bodyLarge),
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

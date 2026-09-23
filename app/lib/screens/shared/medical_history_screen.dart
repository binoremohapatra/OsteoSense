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
        title: 'Medical History',
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
                      'Past Medical History',
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'For ${widget.side} ${widget.jointId}',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    _buildSwitchTile(
                      'Previous Diagnosis of Arthritis',
                      _previousDiagnosis,
                      (val) => setState(() => _previousDiagnosis = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildSwitchTile(
                      'Previous Joint Pain Episodes',
                      _previousJointPain,
                      (val) => setState(() => _previousJointPain = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildSwitchTile(
                      'Chronic Joint Problems',
                      _chronicJointProblems,
                      (val) => setState(() => _chronicJointProblems = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildSwitchTile(
                      'Previous Joint Inflammation/Swelling',
                      _previousInflammation,
                      (val) => setState(() => _previousInflammation = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildSwitchTile(
                      'History of Injury to this joint',
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        title: Text(title, style: AppTypography.bodyLarge),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

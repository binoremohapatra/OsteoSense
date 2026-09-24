import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/screening_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';

class SurgeryHistoryScreen extends StatefulWidget {
  final int patientId;
  final String jointId;
  final String side;

  const SurgeryHistoryScreen({
    super.key,
    required this.patientId,
    required this.jointId,
    required this.side,
  });

  @override
  State<SurgeryHistoryScreen> createState() => _SurgeryHistoryScreenState();
}

class _SurgeryHistoryScreenState extends State<SurgeryHistoryScreen> {
  bool _hasHadSurgery = false;
  String? _surgeryType;
  bool _implantPresent = false;

  void _proceed() {
    HapticFeedback.mediumImpact();
    // In a real app we'd save this to a SurgeryHistory object
    
    // Now we continue to the expanded symptom questionnaire
    context.push('/screening/symptoms', extra: {
      'patientId': widget.patientId,
      'jointId': widget.jointId,
    }); // we can pass side if we update SymptomQuestionnaireScreen to accept it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'surgery_history'.tr(),
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
                      'past_surgeries'.tr(),
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
                    
                    Material(
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
                            title: Text('have_you_had_surgery_on_this_joint'.tr(), style: AppTypography.bodyLarge),
                            value: _hasHadSurgery,
                            onChanged: (val) => setState(() => _hasHadSurgery = val),
                            activeColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    
                    if (_hasHadSurgery) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'surgery_details'.tr(),
                        style: AppTypography.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'type_of_surgery'.tr(),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => _surgeryType = val,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Material(
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
                              title: Text('are_there_implants_hardware'.tr(), style: AppTypography.bodyLarge),
                              value: _implantPresent,
                              onChanged: (val) => setState(() => _implantPresent = val),
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
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
}

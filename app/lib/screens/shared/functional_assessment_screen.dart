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

class FunctionalAssessmentScreen extends StatefulWidget {
  const FunctionalAssessmentScreen({super.key});

  @override
  State<FunctionalAssessmentScreen> createState() => _FunctionalAssessmentScreenState();
}

class _FunctionalAssessmentScreenState extends State<FunctionalAssessmentScreen> {
  final Map<String, int> _functionalScores = {};

  List<String> _getQuestionsForJoint(String joint) {
    switch (joint.toLowerCase()) {
      case 'knee':
      case 'hip':
      case 'ankle':
        return [
          'Difficulty walking on flat surfaces',
          'Difficulty going up/down stairs',
          'Difficulty squatting or bending',
          'Difficulty standing from a seated position'
        ];
      case 'shoulder':
      case 'elbow':
        return [
          'Difficulty reaching overhead',
          'Difficulty lifting heavy objects',
          'Difficulty dressing/grooming',
          'Difficulty sleeping on affected side'
        ];
      case 'wrist':
      case 'fingers / hand':
        return [
          'Difficulty gripping objects',
          'Difficulty opening jars',
          'Difficulty typing or writing',
          'Difficulty carrying bags'
        ];
      default:
        return [
          'Difficulty with daily activities',
          'Limitation in range of motion',
          'Weakness in the joint',
          'Difficulty bearing weight'
        ];
    }
  }

  void _proceed() {
    HapticFeedback.mediumImpact();
    
    final screeningProvider = context.read<ScreeningProvider>();
    screeningProvider.draftFunctionalMap = _functionalScores;
    
    // Proceed to image upload
    context.push('/screening/image_upload');
  }

  @override
  Widget build(BuildContext context) {
    final screeningProvider = context.read<ScreeningProvider>();
    final jointId = screeningProvider.draftJointId ?? 'Unknown Joint';
    final questions = _getQuestionsForJoint(jointId);

    // Initialize scores to 0 (No difficulty) if not set
    for (var q in questions) {
      if (!_functionalScores.containsKey(q)) {
        _functionalScores[q] = 0;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Functional Assessment',
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
                      'Functional Limitations',
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Rate difficulty (0 = None, 3 = Severe) for $jointId',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    ...questions.map((q) => _buildQuestionCard(q)),
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

  Widget _buildQuestionCard(String question) {
    final score = _functionalScores[question] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final isSelected = score == index;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _functionalScores[question] = index);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('None', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              Text('Severe', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

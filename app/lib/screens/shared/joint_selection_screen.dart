import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/common/index.dart';

class JointSelectionScreen extends StatefulWidget {
  final int? patientId;

  const JointSelectionScreen({super.key, this.patientId});

  @override
  State<JointSelectionScreen> createState() => _JointSelectionScreenState();
}

class _JointSelectionScreenState extends State<JointSelectionScreen> {
  String? _selectedJoint;

  final List<JointOption> _joints = [
    JointOption(
      id: 'knee',
      name: 'Knee',
      icon: Icons.accessibility_new,
      description: 'Most Common',
      isRecommended: true,
    ),
    JointOption(
      id: 'hip',
      name: 'Hip',
      icon: Icons.directions_walk,
      description: 'Mobility Focus',
    ),
    JointOption(
      id: 'ankle',
      name: 'Ankle',
      icon: Icons.directions_run,
      description: 'Balance & Gait',
    ),
    JointOption(
      id: 'shoulder',
      name: 'Shoulder',
      icon: Icons.fitness_center,
      description: 'Upper Limb',
    ),
    JointOption(
      id: 'elbow',
      name: 'Elbow',
      icon: Icons.pan_tool,
      description: 'Movement',
    ),
    JointOption(
      id: 'wrist',
      name: 'Wrist',
      icon: Icons.edit,
      description: 'Fine Motor',
    ),
    JointOption(
      id: 'other',
      name: 'Other Joints',
      icon: Icons.help_outline,
      description: 'Finger, Spine, or Custom',
      hasArrow: true,
    ),
  ];

  void _selectJoint(String jointId) {
    setState(() {
      _selectedJoint = jointId;
    });

    // Navigate to symptom questionnaire
    context.push('/screening/symptoms', extra: {
      'patientId': widget.patientId,
      'jointId': jointId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Select Joint',
        centerTitle: false,
        showBackButton: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/agent/home'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Header
                    Text(
                      'Select Joint',
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: AppMotion.standard),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Which area would you like to screen today?',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(duration: AppMotion.standard, delay: 100.ms),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Joint Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _joints.length,
                      itemBuilder: (context, index) {
                        final joint = _joints[index];
                        return _buildJointCard(joint, index);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/agent/home'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedJoint != null
                          ? () => _selectJoint(_selectedJoint!)
                          : null,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedJoint != null
                            ? AppColors.primary
                            : AppColors.textSecondary.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJointCard(JointOption joint, int index) {
    final isSelected = _selectedJoint == joint.id;
    final isRecommended = joint.isRecommended;

    return GestureDetector(
      onTap: () => _selectJoint(joint.id),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary
                : isRecommended
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.textSecondary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : isRecommended
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  joint.icon,
                  size: 28,
                  color: isSelected
                      ? AppColors.primary
                      : isRecommended
                          ? AppColors.primary.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Name
              Text(
                joint.name,
                style: AppTypography.titleSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              
              // Description
              Text(
                joint.description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Recommended badge
              if (isRecommended) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    'Most Common',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              
              // Arrow for "Other Joints"
              if (joint.hasArrow) ...[
                const SizedBox(height: AppSpacing.xs),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ).animate().fadeIn(
        duration: AppMotion.standard,
        delay: Duration(milliseconds: 50 * index),
      ).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        duration: AppMotion.standard,
        curve: AppMotion.curveSpring,
      ),
    );
  }
}

class JointOption {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final bool isRecommended;
  final bool hasArrow;

  JointOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.isRecommended = false,
    this.hasArrow = false,
  });
}

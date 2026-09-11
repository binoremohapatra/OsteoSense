import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/index.dart';

class AppVersionScreen extends StatelessWidget {
  const AppVersionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'app_version'.tr(),
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            // App Icon
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  size: 64,
                  color: AppColors.primary,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // App Name
            Center(
              child: Text(
                'JointSaathi',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Version Info
            Center(
              child: Text(
                '${'version'.tr()} 1.0.0',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Version Details Card
            CustomCard(
              variant: CardVariant.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVersionDetail('build_number'.tr(), '1'),
                  _buildDivider(),
                  _buildVersionDetail('release_date_label'.tr(), 'September 2026'),
                  _buildDivider(),
                  _buildVersionDetail('flutter_version'.tr(), '3.24.0'),
                  _buildDivider(),
                  _buildVersionDetail('platform'.tr(), 'Android & iOS'),
                  _buildDivider(),
                  _buildVersionDetail('minimum_sdk'.tr(), 'Android 5.0 (API 21)'),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: AppSpacing.xl),
            
            // Features Card
            CustomCard(
              variant: CardVariant.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'features_title'.tr(),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeature('feature_ai_screening'.tr()),
                  _buildFeature('feature_ble'.tr()),
                  _buildFeature('feature_offline'.tr()),
                  _buildFeature('feature_multilang'.tr()),
                  _buildFeature('feature_patient_mgmt'.tr()),
                  _buildFeature('feature_analytics'.tr()),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 500.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: AppSpacing.xl),
            
            // Copyright
            Center(
              child: Text(
                'copyright_text'.tr(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPaddingMd,
        vertical: AppSpacing.cardPaddingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.cardPaddingMd),
      child: Divider(
        color: AppColors.softBorder,
        height: 1,
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPaddingMd,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

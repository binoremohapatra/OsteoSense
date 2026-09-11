import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/index.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'privacy_policy'.tr(),
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('pp_title_1'.tr(), 'pp_content_1'.tr()),
            _buildSection('pp_title_2'.tr(), 'pp_content_2'.tr()),
            _buildSection('pp_title_3'.tr(), 'pp_content_3'.tr()),
            _buildSection('pp_title_4'.tr(), 'pp_content_4'.tr()),
            _buildSection('pp_title_5'.tr(), 'pp_content_5'.tr()),
            _buildSection('pp_title_6'.tr(), 'pp_content_6'.tr()),
            _buildSection('pp_title_7'.tr(), 'pp_content_7'.tr()),
            _buildSection('pp_title_8'.tr(), 'pp_content_8'.tr()),
            _buildSection('pp_title_9'.tr(), 'pp_content_9'.tr()),
            _buildSection('pp_title_10'.tr(), 'pp_content_10'.tr()),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

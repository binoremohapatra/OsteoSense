import 'package:flutter/material.dart';
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
          'Privacy Policy',
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
            _buildSection(
              '1. Information We Collect',
              'We collect personal information including name, contact details, age, gender, and health-related data. We also collect sensor data from wearables, screening results, and usage analytics.',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'Your information is used to provide AI-powered osteoarthritis risk assessments, improve our services, conduct research, and comply with legal obligations. Medical data is processed with appropriate safeguards.',
            ),
            _buildSection(
              '3. Data Storage and Security',
              'All data is stored locally on your device using encrypted SQLite databases. When synchronized, data is transmitted using secure HTTPS connections. We implement industry-standard security measures.',
            ),
            _buildSection(
              '4. Data Sharing',
              'We do not sell your personal information. We may share de-identified data for research purposes with your consent. We may disclose information if required by law or to protect our rights.',
            ),
            _buildSection(
              '5. Your Rights',
              'You have the right to access, correct, or delete your personal data. You can export your data at any time. You may opt out of data collection by discontinuing use of the application.',
            ),
            _buildSection(
              '6. Data Retention',
              'We retain your data only as long as necessary to provide our services and as required by law. You can request deletion of your data at any time through the app settings.',
            ),
            _buildSection(
              '7. Children\'s Privacy',
              'JointSaathi is not intended for use by children under 13. We do not knowingly collect personal information from children.',
            ),
            _buildSection(
              '8. Third-Party Services',
              'We may use third-party services for analytics, cloud storage, and AI processing. These services have their own privacy policies and data handling practices.',
            ),
            _buildSection(
              '9. Changes to This Policy',
              'We may update this privacy policy from time to time. We will notify you of any material changes by posting the new policy on this page.',
            ),
            _buildSection(
              '10. Contact Us',
              'If you have any questions about this privacy policy, please contact us at support@jointsaathi.com',
            ),
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

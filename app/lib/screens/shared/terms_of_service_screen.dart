import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/index.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
              '1. Acceptance of Terms',
              'By using the JointSaathi application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.',
            ),
            _buildSection(
              '2. Medical Disclaimer',
              'JointSaathi is an AI-assisted screening tool for osteoarthritis risk assessment. It is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with qualified healthcare professionals for medical decisions.',
            ),
            _buildSection(
              '3. User Responsibilities',
              'Users are responsible for maintaining the confidentiality of their account information and for all activities that occur under their account. Users agree to notify us immediately of any unauthorized use of their account.',
            ),
            _buildSection(
              '4. Data Collection and Use',
              'We collect patient data, screening results, and sensor information to provide AI-powered risk assessments. Your data is processed locally on your device and synchronized when connectivity is available.',
            ),
            _buildSection(
              '5. Privacy and Security',
              'We implement reasonable security measures to protect your data. However, no method of transmission over the internet is completely secure, and we cannot guarantee absolute security.',
            ),
            _buildSection(
              '6. Intellectual Property',
              'All content, features, and functionality of the JointSaathi application are owned by us and are protected by international copyright, trademark, and other intellectual property laws.',
            ),
            _buildSection(
              '7. Limitation of Liability',
              'In no event shall we be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of the application.',
            ),
            _buildSection(
              '8. Modifications to Terms',
              'We reserve the right to modify these terms at any time. Your continued use of the application after such modifications constitutes your acceptance of the updated terms.',
            ),
            _buildSection(
              '9. Termination',
              'We reserve the right to terminate or suspend your access to the application at any time, without prior notice, for any reason, including but not limited to violation of these terms.',
            ),
            _buildSection(
              '10. Governing Law',
              'These terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
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

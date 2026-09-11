import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/custom_card.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/splash');
            }
          },
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              // Language icon with animation
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language,
                  size: 40,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: AppSpacing.xl),
              // Title
              Text(
                'select_language'.tr(),
                style: AppTypography.headlineLarge,
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms),
              const SizedBox(height: AppSpacing.sm),
              // Subtitle
              Text(
                'choose_language'.tr(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 300.ms),
              const SizedBox(height: AppSpacing.xxxl),
              // Language options
              _buildLanguageOption(
                context,
                'English',
                'en',
                Icons.flag,
                0,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'हिंदी',
                'hi',
                Icons.translate,
                50,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'বাংলা',
                'bn',
                Icons.translate,
                100,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'অসমীয়া',
                'as',
                Icons.translate,
                150,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'ગુજરાતી',
                'gu',
                Icons.translate,
                200,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'ಕನ್ನಡ',
                'kn',
                Icons.translate,
                250,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'മലയാളം',
                'ml',
                Icons.translate,
                300,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'मराठी',
                'mr',
                Icons.translate,
                350,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'ଓଡ଼ିଆ',
                'or',
                Icons.translate,
                400,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'ਪੰਜਾਬੀ',
                'pa',
                Icons.translate,
                450,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'தமிழ்',
                'ta',
                Icons.translate,
                500,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLanguageOption(
                context,
                'తెలుగు',
                'te',
                Icons.translate,
                550,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageName,
    String languageCode,
    IconData icon,
    int delayMs,
  ) {
    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: () async {
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        await settingsProvider.setLanguage(languageCode);
        
        // Change app locale
        if (context.mounted) {
          await context.setLocale(Locale(languageCode));
          
          // Go back or navigate to next screen
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/role');
          }
        }
      },
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              languageName,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delayMs)).slideY(
      begin: 0.2,
      end: 0,
      duration: 400.ms,
      delay: Duration(milliseconds: delayMs),
    );
  }
}

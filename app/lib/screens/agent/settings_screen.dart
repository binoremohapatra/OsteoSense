import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/index.dart';
import '../shared/terms_of_service_screen.dart';
import '../shared/privacy_policy_screen.dart';
import '../shared/app_version_screen.dart';
import '../shared/storage_usage_screen.dart';
import '../shared/notifications_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'settings'.tr(),
        centerTitle: false,
        showBackButton: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  'assets/images/03_dashboard.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Settings Section
            _buildSectionHeader('app_settings'.tr())
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.md),
            _buildSettingGroup([
              _buildSettingItem(
                icon: Icons.notifications_active,
                title: 'notifications_title'.tr(),
                subtitle: settingsProvider.notificationsEnabled ? 'enabled'.tr() : 'disabled'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsSettingsScreen()),
                ),
              ),
            ]).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            const SizedBox(height: AppSpacing.xl),

            // Sync & Data Section
            _buildSectionHeader('sync_data'.tr())
                .animate()
                .fadeIn(duration: 300.ms, delay: 150.ms),
            const SizedBox(height: AppSpacing.md),
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return _buildSettingGroup([
                  _buildToggleSetting(
                    icon: Icons.cloud_sync,
                    title: 'auto_sync'.tr(),
                    value: settingsProvider.autoSyncEnabled,
                    onChanged: (value) {
                      settingsProvider.setAutoSyncEnabled(value);
                    },
                  ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.storage,
                title: 'storage_usage'.tr(),
                subtitle: '${(5.2).toStringAsFixed(1)} MB',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StorageUsageScreen()),
                ),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.language,
                title: 'language'.tr(),
                subtitle: settingsProvider.language.toUpperCase(),
                onTap: () => _showLanguageDialog(context, settingsProvider),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.delete_outline,
                title: 'clear_cache'.tr(),
                subtitle: 'clear_cache_subtitle'.tr(),
                onTap: () => _showClearCacheDialog(context),
              ),
                ]);
              },
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
            const SizedBox(height: AppSpacing.xl),

            // About Section
            _buildSectionHeader('about'.tr())
                .animate()
                .fadeIn(duration: 300.ms, delay: 250.ms),
            const SizedBox(height: AppSpacing.md),
            _buildSettingGroup([
              _buildSettingItem(
                icon: Icons.info,
                title: 'app_version'.tr(),
                subtitle: '1.0.0',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppVersionScreen()),
                ),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.description,
                title: 'terms_of_service'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
                ),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.privacy_tip,
                title: 'privacy_policy'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                ),
              ),
            ]).animate().fadeIn(duration: 300.ms, delay: 300.ms),
            const SizedBox(height: AppSpacing.xl),

            // Danger Zone
            _buildSectionHeader('danger_zone'.tr(), isDanger: true)
                .animate()
                .fadeIn(duration: 300.ms, delay: 350.ms),
            const SizedBox(height: AppSpacing.md),
            _buildSettingGroup([
              _buildSettingItem(
                icon: Icons.refresh,
                title: 'reset_database'.tr(),
                subtitle: 'reset_database_subtitle'.tr(),
                isDanger: true,
                onTap: () => _showResetDatabaseDialog(context),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.logout,
                title: 'logout'.tr(),
                subtitle: 'logout_subtitle'.tr(),
                isDanger: true,
                onTap: () => _showLogoutDialog(context),
              ),
            ]).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDanger = false}) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: isDanger ? AppColors.error : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSettingGroup(List<Widget> children) {
    return CustomCard(
      variant: CardVariant.elevated,
      padding: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPaddingMd,
            vertical: AppSpacing.cardPaddingMd,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDanger
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDanger ? AppColors.error : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDanger ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
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

  Widget _buildToggleSetting({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPaddingMd,
        vertical: AppSpacing.cardPaddingMd,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primarySurface,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'select_language'.tr(),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('English', 'en', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('हिंदी', 'hi', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('বাংলা', 'bn', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('অসমীয়া', 'as', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('ગુજરાતી', 'gu', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('ಕನ್ನಡ', 'kn', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('മലയാളം', 'ml', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('मराठी', 'mr', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('ଓଡ଼ିଆ', 'or', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('ਪੰਜਾਬੀ', 'pa', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('தமிழ்', 'ta', provider),
              const SizedBox(height: AppSpacing.sm),
              _buildLanguageOption('తెలుగు', 'te', provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code, SettingsProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          provider.setLanguage(code);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      
      // Delete all files in temp directory
      if (await tempDir.exists()) {
        final List<FileSystemEntity> entities = tempDir.listSync();
        for (FileSystemEntity entity in entities) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cache_cleared_successfully'.tr()),
            backgroundColor: AppColors.riskLow,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_clear_cache'.tr(namedArgs: {'e': '$e'})),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'clear_cache_question'.tr(),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'clear_cache_warning'.tr(),
          style: AppTypography.bodyMedium,
        ),
        actions: [
          CustomButton(
            text: 'cancel'.tr(),
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
          ),
          CustomButton(
            text: 'clear'.tr(),
            onPressed: () async {
              Navigator.pop(context);
              await _clearCache(context);
            },
            variant: ButtonVariant.danger,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showResetDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'reset_database_question'.tr(),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'reset_database_warning'.tr(),
          style: AppTypography.bodyMedium,
        ),
        actions: [
          CustomButton(
            text: 'cancel'.tr(),
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
          ),
          CustomButton(
            text: 'reset'.tr(),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final db = DatabaseHelper();
                await db.resetDatabase();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('database_reset_success_msg'.tr()),
                      backgroundColor: AppColors.riskLow,
                    ),
                  );
                  // Navigate to splash screen to reinitialize
                  context.go('/splash');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('failed_to_reset_database'.tr(namedArgs: {'e': '$e'})),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            variant: ButtonVariant.danger,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'logout_question'.tr(),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'logout_warning'.tr(),
          style: AppTypography.bodyMedium,
        ),
        actions: [
          CustomButton(
            text: 'cancel'.tr(),
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
          ),
          CustomButton(
            text: 'logout_button'.tr(),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              Navigator.pop(context);
              Future.microtask(() {
                if (context.mounted) {
                  context.go('/role');
                }
              });
            },
            variant: ButtonVariant.danger,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }
}

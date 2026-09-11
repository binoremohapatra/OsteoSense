import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/index.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

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
          'notifications'.tr(),
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
            const SizedBox(height: AppSpacing.xl),
            
            // Header
            Text(
              'manage_notifications'.tr(),
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ).animate().fadeIn(duration: 600.ms),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Notification Types
            _buildSectionHeader('notification_types'.tr())
                .animate().fadeIn(duration: 600.ms, delay: 200.ms),
            const SizedBox(height: AppSpacing.md),
            
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return _buildSettingGroup([
                  _buildToggleSetting(
                    icon: Icons.notifications_active,
                    title: 'push_notifications'.tr(),
                    subtitle: 'push_notifications_description'.tr(),
                    value: settingsProvider.pushNotificationsEnabled,
                    onChanged: (value) {
                      settingsProvider.setPushNotificationsEnabled(value);
                    },
                  ),
                  _buildDivider(),
                  _buildToggleSetting(
                    icon: Icons.event,
                    title: 'screening_reminders'.tr(),
                    subtitle: 'screening_reminders_description'.tr(),
                    value: settingsProvider.screeningRemindersEnabled,
                    onChanged: (value) {
                      settingsProvider.setScreeningRemindersEnabled(value);
                    },
                  ),
                  _buildDivider(),
                  _buildToggleSetting(
                    icon: Icons.medical_services,
                    title: 'health_alerts'.tr(),
                    subtitle: 'health_alerts_description'.tr(),
                    value: settingsProvider.healthAlertsEnabled,
                    onChanged: (value) {
                      settingsProvider.setHealthAlertsEnabled(value);
                    },
                  ),
                ]).animate().fadeIn(duration: 600.ms, delay: 300.ms);
              },
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Notification Preferences
            _buildSectionHeader('preferences'.tr())
                .animate().fadeIn(duration: 600.ms, delay: 400.ms),
            const SizedBox(height: AppSpacing.md),
            
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return _buildSettingGroup([
                  _buildSettingItem(
                    icon: Icons.schedule,
                    title: 'quiet_hours'.tr(),
                    subtitle: settingsProvider.quietHoursEnabled
                        ? '${settingsProvider.quietHoursStart} - ${settingsProvider.quietHoursEnd}'
                        : 'no_notifications_during_sleep'.tr(),
                    onTap: () => _showQuietHoursDialog(context, settingsProvider),
                  ),
                  _buildDivider(),
                  _buildToggleSetting(
                    icon: Icons.vibration,
                    title: 'vibration'.tr(),
                    subtitle: 'vibration_description'.tr(),
                    value: settingsProvider.vibrationEnabled,
                    onChanged: (value) {
                      settingsProvider.setVibrationEnabled(value);
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.volume_up,
                    title: 'sound'.tr(),
                    subtitle: _getLocalizedSound(settingsProvider.notificationSound),
                    onTap: () => _showSoundDialog(context, settingsProvider),
                  ),
                ]).animate().fadeIn(duration: 600.ms, delay: 500.ms);
              },
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Info Section
            CustomCard(
              variant: CardVariant.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'about_notifications'.tr(),
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'about_notifications_description'.tr(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
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

  Widget _buildToggleSetting({
    required IconData icon,
    required String title,
    String? subtitle,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primarySurface,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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

  String _getLocalizedSound(String sound) {
    switch (sound) {
      case 'Default':
        return 'default_sound'.tr();
      case 'Chime':
        return 'chime'.tr();
      case 'Alert':
        return 'alert'.tr();
      default:
        return sound;
    }
  }

  void _showQuietHoursDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'quiet_hours'.tr(),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('enable_quiet_hours'.tr()),
              value: settingsProvider.quietHoursEnabled,
              onChanged: (value) {
                settingsProvider.setQuietHoursEnabled(value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              title: Text('start_time'.tr()),
              trailing: Text(settingsProvider.quietHoursStart),
              onTap: () => _showTimePicker(dialogContext, true, settingsProvider),
            ),
            ListTile(
              title: Text('end_time'.tr()),
              trailing: Text(settingsProvider.quietHoursEnd),
              onTap: () => _showTimePicker(dialogContext, false, settingsProvider),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'cancel'.tr(),
            onPressed: () => Navigator.pop(dialogContext),
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
          ),
          CustomButton(
            text: 'save'.tr(),
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('quiet_hours_saved'.tr())),
              );
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showTimePicker(BuildContext context, bool isStartTime, SettingsProvider settingsProvider) {
    final currentTime = isStartTime
        ? settingsProvider.quietHoursStart
        : settingsProvider.quietHoursEnd;
    final parts = currentTime.split(':');
    final initialHour = int.tryParse(parts[0]) ?? 22;
    final initialMinute = int.tryParse(parts[1]) ?? 0;

    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    ).then((selectedTime) {
      if (selectedTime != null) {
        final formattedTime =
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
        if (isStartTime) {
          settingsProvider.setQuietHoursStart(formattedTime);
        } else {
          settingsProvider.setQuietHoursEnd(formattedTime);
        }
      }
    });
  }

  void _showSoundDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'notification_sound'.tr(),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSoundOption(dialogContext, 'default_sound'.tr(), settingsProvider),
            const SizedBox(height: AppSpacing.sm),
            _buildSoundOption(dialogContext, 'chime'.tr(), settingsProvider),
            const SizedBox(height: AppSpacing.sm),
            _buildSoundOption(dialogContext, 'alert'.tr(), settingsProvider),
          ],
        ),
        actions: [
          CustomButton(
            text: 'cancel'.tr(),
            onPressed: () => Navigator.pop(dialogContext),
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundOption(BuildContext dialogContext, String sound, SettingsProvider settingsProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          settingsProvider.setNotificationSound(sound);
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(content: Text('sound_set'.tr())),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  sound,
                  style: AppTypography.bodyMedium,
                ),
              ),
              if (settingsProvider.notificationSound == sound)
                const Icon(Icons.check, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

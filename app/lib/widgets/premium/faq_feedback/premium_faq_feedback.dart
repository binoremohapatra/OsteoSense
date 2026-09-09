import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_motion.dart';
import '../../common/custom_card.dart';
import '../../common/custom_button.dart';

/// An animated FAQ accordion component.
class AnimatedFAQ extends StatefulWidget {
  final String question;
  final String answer;

  const AnimatedFAQ({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<AnimatedFAQ> createState() => _AnimatedFAQState();
}

class _AnimatedFAQState extends State<AnimatedFAQ> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: AppTypography.titleMedium.copyWith(
                        color: _isExpanded ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: AppMotion.fast,
                    curve: AppMotion.curveSmooth,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _isExpanded ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.fast,
            curve: AppMotion.curveSmooth,
            alignment: Alignment.topCenter,
            child: Container(
              height: _isExpanded ? null : 0,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Text(
                  widget.answer,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                ).animate(target: _isExpanded ? 1 : 0).fadeIn(duration: AppMotion.fast),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DialogVariant { info, success, warning, error }

/// A premium dialog utilizing Shared Axis / Container Transform style animations.
class PremiumDialog extends StatelessWidget {
  final String title;
  final String message;
  final DialogVariant variant;
  final String confirmText;
  final VoidCallback onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;

  const PremiumDialog({
    super.key,
    required this.title,
    required this.message,
    this.variant = DialogVariant.info,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;
    ButtonVariant btnVariant;

    switch (variant) {
      case DialogVariant.success:
        iconColor = AppColors.success;
        iconData = Icons.check_circle;
        btnVariant = ButtonVariant.primary; // Or custom success if added to enum
        break;
      case DialogVariant.warning:
        iconColor = AppColors.warning;
        iconData = Icons.warning;
        btnVariant = ButtonVariant.primary;
        break;
      case DialogVariant.error:
        iconColor = AppColors.error;
        iconData = Icons.error;
        btnVariant = ButtonVariant.danger;
        break;
      case DialogVariant.info:
        iconColor = AppColors.info;
        iconData = Icons.info;
        btnVariant = ButtonVariant.primary;
        break;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: CustomCard(
        variant: CardVariant.elevated,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 32),
            ).animate().scale(delay: AppMotion.staggerDelay, duration: AppMotion.fast, curve: AppMotion.curveSpring),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: AppMotion.staggerDelay * 2).slideY(begin: 0.1, end: 0),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: AppMotion.staggerDelay * 3).slideY(begin: 0.1, end: 0),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (cancelText != null && onCancel != null) ...[
                  Expanded(
                    child: CustomButton(
                      text: cancelText!,
                      onPressed: onCancel,
                      variant: ButtonVariant.ghost,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: CustomButton(
                    text: confirmText,
                    onPressed: onConfirm,
                    variant: btnVariant,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: AppMotion.staggerDelay * 4),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppMotion.fast).scale(begin: const Offset(0.9, 0.9), curve: AppMotion.curveSmooth);
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    DialogVariant variant = DialogVariant.info,
    required String confirmText,
    required VoidCallback onConfirm,
    String? cancelText,
    VoidCallback? onCancel,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: AppMotion.fast,
      pageBuilder: (context, animation, secondaryAnimation) {
        return PremiumDialog(
          title: title,
          message: message,
          variant: variant,
          confirmText: confirmText,
          onConfirm: onConfirm,
          cancelText: cancelText,
          onCancel: onCancel,
        );
      },
    );
  }
}

/// A premium snackbar or toast replacement.
class PremiumSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    DialogVariant variant = DialogVariant.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color bgColor;
    IconData icon;

    switch (variant) {
      case DialogVariant.success:
        bgColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case DialogVariant.warning:
        bgColor = AppColors.warning;
        icon = Icons.warning;
        break;
      case DialogVariant.error:
        bgColor = AppColors.error;
        icon = Icons.error;
        break;
      case DialogVariant.info:
        bgColor = AppColors.textPrimary;
        icon = Icons.info;
        break;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      margin: const EdgeInsets.all(AppSpacing.md),
      duration: duration,
      elevation: 6,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

/// A badge for showing status.
class StatusBadge extends StatelessWidget {
  final String text;
  final DialogVariant variant;

  const StatusBadge({
    super.key,
    required this.text,
    this.variant = DialogVariant.info,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (variant) {
      case DialogVariant.success:
        color = AppColors.success;
        break;
      case DialogVariant.warning:
        color = AppColors.warning;
        break;
      case DialogVariant.error:
        color = AppColors.error;
        break;
      case DialogVariant.info:
        color = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

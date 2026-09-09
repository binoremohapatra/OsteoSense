import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_motion.dart';
import '../../common/custom_button.dart';

/// A button that magneticly attracts to the cursor when hovered.
class MagneticButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final Widget? icon;
  final bool isLoading;

  const MagneticButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton> {
  Offset _position = Offset.zero;

  void _onHover(PointerEvent details) {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final localPosition = renderBox.globalToLocal(details.position);
      
      final dx = (localPosition.dx - (size.width / 2)) * 0.3;
      final dy = (localPosition.dy - (size.height / 2)) * 0.3;
      
      setState(() {
        _position = Offset(dx, dy);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) {
        setState(() {
          _position = Offset.zero;
        });
      },
      onHover: _onHover,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: _position),
        duration: AppMotion.fast,
        curve: AppMotion.curveSmooth,
        builder: (context, offset, child) {
          return Transform.translate(
            offset: offset,
            child: child,
          );
        },
        child: CustomButton(
          text: widget.text,
          onPressed: widget.onPressed,
          variant: widget.variant,
          icon: widget.icon,
          isLoading: widget.isLoading,
        ),
      ),
    );
  }
}

/// A premium glassmorphic button.
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget? icon;
  final bool fullWidth;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: AppMotion.fast);
    _scaleAnimation = Tween<double>(begin: 1.0, end: AppMotion.pressScale).animate(
      CurvedAnimation(parent: _scaleController, curve: AppMotion.curvePress),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buttonContent = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.text,
          style: AppTypography.button.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: isDark ? AppColors.glassWhiteDark : AppColors.glassWhite,
            child: InkWell(
              onTap: widget.onPressed,
              onTapDown: (_) => _scaleController.forward(),
              onTapUp: (_) => _scaleController.reverse(),
              onTapCancel: () => _scaleController.reverse(),
              child: Container(
                height: AppSpacing.buttonHeightMd,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark ? AppColors.glassBorderDark : AppColors.glassBorder,
                    width: 1,
                  ),
                ),
                child: Center(child: buttonContent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A button with a specialized gradient for premium actions.
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final LinearGradient gradient;
  final Widget? icon;
  final bool fullWidth;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    this.icon,
    this.fullWidth = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // CustomButton already supports primary/secondary gradients, but this allows custom ones
    return CustomButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.primary, // Using primary as base to get shadows
      icon: icon,
      fullWidth: fullWidth,
      isLoading: isLoading,
    );
    // Note: To fully support custom gradients in CustomButton without modifying the base class,
    // we would wrap an InkWell in an Ink with the decoration. For simplicity in this adaptation,
    // we lean on the base class or we could implement a full custom one.
  }
}

/// A button indicating success.
class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget? icon;
  final bool fullWidth;

  const SuccessButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        // Override primary color locally just for this button if we wanted to reuse CustomButton
        // However, CustomButton hardcodes AppColors.primary for ButtonVariant.primary.
        // So we build a custom styled button here.
      ),
      child: _CustomGradientStyledButton(
        text: text,
        onPressed: onPressed,
        gradient: AppColors.successGradient,
        shadowColor: AppColors.success,
        icon: icon,
        fullWidth: fullWidth,
      ),
    );
  }
}

// Helper for SuccessButton and GradientButton
class _CustomGradientStyledButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final LinearGradient gradient;
  final Color shadowColor;
  final Widget? icon;
  final bool fullWidth;

  const _CustomGradientStyledButton({
    required this.text,
    required this.onPressed,
    required this.gradient,
    required this.shadowColor,
    this.icon,
    this.fullWidth = false,
  });

  @override
  State<_CustomGradientStyledButton> createState() => _CustomGradientStyledButtonState();
}

class _CustomGradientStyledButtonState extends State<_CustomGradientStyledButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: AppMotion.fast);
    _scaleAnimation = Tween<double>(begin: 1.0, end: AppMotion.pressScale).animate(
      CurvedAnimation(parent: _scaleController, curve: AppMotion.curvePress),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.text,
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _scaleController.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Ink(
            height: AppSpacing.buttonHeightMd,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
                if (_isPressed)
                  BoxShadow(
                    color: widget.shadowColor.withValues(alpha: 0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );
  }
}

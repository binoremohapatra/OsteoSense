import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_motion.dart';
import '../../common/custom_card.dart';

/// A premium glassmorphic card utilizing BackdropFilter.
/// References: liquid_glass_widgets styling but adapted to JointSaathi colors.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPaddingMd),
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassWhiteDark : AppColors.glassWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: cardContent,
        ),
      ).animate().fadeIn(duration: AppMotion.fast).scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1, 1),
        duration: AppMotion.fast,
        curve: AppMotion.curve,
      );
    }

    return cardContent.animate().fadeIn(duration: AppMotion.fast);
  }
}

/// A card that responds to hover and touch with a subtle tilt/parallax effect.
class ParallaxCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const ParallaxCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _localOffset = Offset.zero;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      lowerBound: -1.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent details) {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final localPosition = renderBox.globalToLocal(details.position);
      
      // Calculate normalized offset from center (-1 to 1)
      final dx = (localPosition.dx - (size.width / 2)) / (size.width / 2);
      final dy = (localPosition.dy - (size.height / 2)) / (size.height / 2);
      
      setState(() {
        _localOffset = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Max tilt angle in radians
    const maxTilt = 0.05;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) {
        setState(() {
          _isHovering = false;
          _localOffset = Offset.zero;
        });
      },
      onHover: _onHover,
      child: GestureDetector(
        onPanUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final size = renderBox.size;
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final dx = (localPosition.dx - (size.width / 2)) / (size.width / 2);
            final dy = (localPosition.dy - (size.height / 2)) / (size.height / 2);
            setState(() {
              _localOffset = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
            });
          }
        },
        onPanEnd: (_) => setState(() => _localOffset = Offset.zero),
        onTap: widget.onTap,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(
            begin: Offset.zero,
            end: _isHovering ? _localOffset : Offset.zero,
          ),
          duration: AppMotion.fast,
          curve: AppMotion.curveSmooth,
          builder: (context, offset, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateX(-offset.dy * maxTilt)
                ..rotateY(offset.dx * maxTilt),
              alignment: FractionalOffset.center,
              child: CustomCard(
                width: widget.width,
                height: widget.height,
                variant: CardVariant.elevated, // Elevated to show depth
                child: child!,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// A standard card with a specific tap animation and focus states.
class InteractiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const InteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      isClickable: true,
      onTap: onTap,
      child: child,
    );
  }
}

/// Card for displaying a key metric or statistic.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final bool? isPositiveTrend;
  final IconData? icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    this.isPositiveTrend,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              if (icon != null)
                Icon(icon, size: 16, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(duration: AppMotion.fast), // Using fadeIn instead of count due to limitations
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  isPositiveTrend == true
                      ? Icons.arrow_upward
                      : isPositiveTrend == false
                          ? Icons.arrow_downward
                          : Icons.horizontal_rule,
                  size: 14,
                  color: isPositiveTrend == true
                      ? AppColors.success
                      : isPositiveTrend == false
                          ? AppColors.error
                          : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  trend!,
                  style: AppTypography.caption.copyWith(
                    color: isPositiveTrend == true
                        ? AppColors.success
                        : isPositiveTrend == false
                            ? AppColors.error
                            : AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

/// Specialized card for patient listings.
class PatientCard extends StatelessWidget {
  final String name;
  final String riskLevel; // "Low", "Medium", "High"
  final String subtitle;
  final VoidCallback onTap;

  const PatientCard({
    super.key,
    required this.name,
    required this.riskLevel,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    CardVariant variant;
    Color badgeColor;
    switch (riskLevel.toLowerCase()) {
      case 'high':
        variant = CardVariant.riskHigh;
        badgeColor = AppColors.riskHigh;
        break;
      case 'medium':
        variant = CardVariant.riskMedium;
        badgeColor = AppColors.riskMedium;
        break;
      case 'low':
      default:
        variant = CardVariant.riskLow;
        badgeColor = AppColors.riskLow;
        break;
    }

    return CustomCard(
      variant: variant,
      isClickable: true,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              riskLevel.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that can expand to show additional content.
class ExpandableCard extends StatefulWidget {
  final Widget title;
  final Widget content;
  final bool initiallyExpanded;

  const ExpandableCard({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                Expanded(child: widget.title),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: AppMotion.fast,
                  child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                ),
              ],
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
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: widget.content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium action card typically used on home screens for main CTAs.
class PremiumActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const PremiumActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconBackgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      isClickable: true,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// An AI insight card that displays a glowing, premium summary or recommendation.
class AIInsightCard extends StatelessWidget {
  final String title;
  final String insight;
  final IconData icon;

  const AIInsightCard({
    super.key,
    required this.title,
    required this.insight,
    this.icon = Icons.auto_awesome_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            insight,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

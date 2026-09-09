import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_motion.dart';
import '../../common/custom_card.dart';

/// Base shimmer effect wrapper.
class PremiumShimmer extends StatelessWidget {
  final Widget child;

  const PremiumShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      period: AppMotion.ambient,
      child: child,
    );
  }
}

/// A generic skeleton block.
class SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Shimmer will tint this
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton loader for a generic card.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const PremiumShimmer(
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBlock(width: 120, height: 16),
            SizedBox(height: AppSpacing.sm),
            SkeletonBlock(width: double.infinity, height: 24),
            SizedBox(height: AppSpacing.md),
            SkeletonBlock(width: 80, height: 16),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for a patient profile or list item.
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return const PremiumShimmer(
      child: CustomCard(
        child: Row(
          children: [
            SkeletonBlock(width: 48, height: 48, borderRadius: 24),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 150, height: 18),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBlock(width: 100, height: 14),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            SkeletonBlock(width: 40, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

/// A subtle, premium pulse loader, often used for sensors or BLE scanning.
class PulseLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const PulseLoader({
    super.key,
    this.size = 48.0,
    this.color,
  });

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.countUp,
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 1.0 - _controller.value,
              child: Transform.scale(
                scale: 1.0 + (_controller.value * 1.5),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            Container(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }
}

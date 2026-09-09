import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';


/// A mesh gradient background using animated blurred blobs.
/// Minimalist and performant enough for modern devices.
class MeshGradientBackground extends StatefulWidget {
  final Widget child;
  final bool isRiskMode;
  final String riskLevel;

  const MeshGradientBackground({
    super.key,
    required this.child,
    this.isRiskMode = false,
    this.riskLevel = 'low',
  });

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.backgroundDark : AppColors.background;

    Color blob1Color = AppColors.meshPrimary;
    Color blob2Color = AppColors.meshAccent;

    if (widget.isRiskMode) {
      final riskColor = AppColors.getRiskColor(widget.riskLevel);
      blob1Color = riskColor.withValues(alpha: 0.15);
      blob2Color = riskColor.withValues(alpha: 0.05);
    } else if (isDark) {
      blob1Color = AppColors.primaryDark.withValues(alpha: 0.2);
      blob2Color = AppColors.accentDark.withValues(alpha: 0.1);
    }

    return Stack(
      children: [
        Container(color: baseColor),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _MeshPainter(
                progress: _controller.value,
                color1: blob1Color,
                color2: blob2Color,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Glass overlay to smooth out the blobs
        Positioned.fill(
          child: Container(
            color: (isDark ? AppColors.backgroundDark : AppColors.background).withValues(alpha: 0.5),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;

  _MeshPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = color1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    final paint2 = Paint()
      ..color = color2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    // Calculate orbiting positions based on progress
    final t = progress * 2 * math.pi;

    final cx1 = size.width * 0.5 + math.cos(t) * size.width * 0.3;
    final cy1 = size.height * 0.3 + math.sin(t * 1.5) * size.height * 0.2;

    final cx2 = size.width * 0.5 + math.sin(t * 0.8) * size.width * 0.4;
    final cy2 = size.height * 0.7 + math.cos(t * 1.2) * size.height * 0.2;

    canvas.drawCircle(Offset(cx1, cy1), size.width * 0.6, paint1);
    canvas.drawCircle(Offset(cx2, cy2), size.width * 0.5, paint2);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color1 != color1 ||
           oldDelegate.color2 != color2;
  }
}

/// A simpler background with floating blobs, useful for onboarding or hero screens.
class FloatingBlobBackground extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color blobColor;

  const FloatingBlobBackground({
    super.key,
    required this.child,
    this.baseColor = AppColors.primarySurface,
    this.blobColor = AppColors.primaryLight,
  });

  @override
  State<FloatingBlobBackground> createState() => _FloatingBlobBackgroundState();
}

class _FloatingBlobBackgroundState extends State<FloatingBlobBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: widget.baseColor),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _BlobPainter(
                progress: _controller.value,
                color: widget.blobColor.withValues(alpha: 0.3),
              ),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BlobPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Simple vertical floating
    final yOffset = math.sin(progress * math.pi) * 100;
    
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2 + yOffset), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8 - yOffset), 180, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';

import '../../../theme/app_typography.dart';
import '../../../theme/app_motion.dart';


/// A health trend line chart using fl_chart.
class HealthTrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  final bool isPositiveTrend;
  final double maxY;

  const HealthTrendChart({
    super.key,
    required this.spots,
    this.isPositiveTrend = true,
    this.maxY = 100,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isPositiveTrend
        ? [AppColors.success, AppColors.success.withValues(alpha: 0.1)]
        : [AppColors.warning, AppColors.warning.withValues(alpha: 0.1)];
    final lineColor = isPositiveTrend ? AppColors.success : AppColors.warning;

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'D${value.toInt()}',
                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: spots.isNotEmpty ? spots.last.x : 7,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    spot.y.toStringAsFixed(1),
                    AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ).animate().fadeIn(duration: AppMotion.slow).scale(curve: AppMotion.curveSmooth),
    );
  }
}

/// A donut chart showing the distribution of risk levels.
class RiskDistributionChart extends StatelessWidget {
  final double lowPercentage;
  final double mediumPercentage;
  final double highPercentage;

  const RiskDistributionChart({
    super.key,
    required this.lowPercentage,
    required this.mediumPercentage,
    required this.highPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: AppColors.riskLow,
              value: lowPercentage,
              title: '${lowPercentage.toInt()}%',
              radius: 40,
              titleStyle: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              color: AppColors.riskMedium,
              value: mediumPercentage,
              title: '${mediumPercentage.toInt()}%',
              radius: 45,
              titleStyle: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              color: AppColors.riskHigh,
              value: highPercentage,
              title: '${highPercentage.toInt()}%',
              radius: 50,
              titleStyle: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ).animate().fadeIn(duration: AppMotion.slow).scale(curve: AppMotion.curveSmooth),
    );
  }
}

/// A custom painted gauge that animates to the risk score.
class RiskGauge extends StatefulWidget {
  final double score; // 0.0 to 1.0
  final double size;

  const RiskGauge({
    super.key,
    required this.score,
    this.size = 200,
  });

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.countUpLong);
    _animation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.curveSmooth),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(RiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: AppMotion.curveSmooth),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value;
        final color = AppColors.lerpRiskColor(currentScore);
        
        return SizedBox(
          width: widget.size,
          height: widget.size / 2, // Semi-circle
          child: CustomPaint(
            painter: _GaugePainter(
              score: currentScore,
              color: color,
              backgroundColor: AppColors.border,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(currentScore * 100).toInt()}%',
                    style: AppTypography.displayMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    currentScore < 0.33 ? 'LOW RISK' : currentScore < 0.66 ? 'MEDIUM RISK' : 'HIGH RISK',
                    style: AppTypography.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final Color backgroundColor;

  _GaugePainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Draw background arc (pi radians)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Draw filled arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * score,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

/// A simple self-drawing sparkline.
class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double width;
  final double height;

  const Sparkline({
    super.key,
    required this.data,
    this.color = AppColors.primary,
    this.width = 100,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(width: width, height: height);

    return SizedBox(
      width: width,
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: AppMotion.countUp,
        curve: AppMotion.curveSmooth,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _SparklinePainter(data: data, color: color, progress: value),
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double progress;

  _SparklinePainter({required this.data, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final min = data.reduce(math.min);
    final max = data.reduce(math.max);
    final range = max - min == 0 ? 1.0 : max - min;

    final path = Path();
    final xStep = size.width / (data.length - 1);

    final pointsToDraw = (data.length * progress).ceil();

    for (int i = 0; i < pointsToDraw; i++) {
      final x = i * xStep;
      final y = size.height - ((data[i] - min) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

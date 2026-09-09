import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// PatientRowWidget — a compact patient list item card.
///
/// Used in: Dashboard (Recent Patients), Patient List screen.
/// Uses JointSaathi card style: white bg, 24px radius, soft border.
/// Risk label: pill-shaped with muted semantic colors.
class PatientRowWidget extends StatefulWidget {
  const PatientRowWidget({
    super.key,
    Color? bgColor,
    String? initials,
    String? lastScreening,
    String? name,
    Color? riskBg,
    String? riskLabel,
    Color? riskText,
    Color? textColor,
    String? patientId,
  })  : this.bgColor = bgColor ?? const Color(0xFFECF3EC),
        this.initials = initials ?? 'RK',
        this.lastScreening = lastScreening ?? '2 hours ago • Knee',
        this.name = name ?? 'Rajesh Kumar',
        this.riskBg = riskBg ?? const Color(0xFFECF3EC),
        this.riskLabel = riskLabel ?? 'LOW RISK',
        this.riskText = riskText ?? const Color(0xFF7A9E82),
        this.textColor = textColor ?? const Color(0xFF2F302E),
        this.patientId = patientId;

  final Color bgColor;
  final String initials;
  final String lastScreening;
  final String name;
  final Color riskBg;
  final String riskLabel;
  final Color riskText;
  final Color textColor;
  final String? patientId;

  @override
  State<PatientRowWidget> createState() => _PatientRowWidgetState();
}

class _PatientRowWidgetState extends State<PatientRowWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        if (widget.patientId != null) {
          context.go('/agent/patient/${widget.patientId}');
        } else {
          context.go('/agent/home');
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.softBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar circle
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.initials,
                    style: AppTypography.labelMedium.copyWith(
                      color: widget.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + metadata
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.lastScreening,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Risk label — pill-shaped, muted semantic colors
                Container(
                  decoration: BoxDecoration(
                    color: widget.riskBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    widget.riskLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: widget.riskText,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../theme/app_colors.dart';

// ============================================================================
// FFPatientRow — production version of FlutterFlow PatientRowWidget
//
// Displays a patient row with initials avatar, name, last screening,
// and a risk pill label. Tappable to navigate to patient detail.
// ============================================================================

class FFPatientRow extends StatelessWidget {
  const FFPatientRow({
    super.key,
    required this.name,
    required this.initials,
    required this.lastScreening,
    required this.riskLabel,
    this.riskBg,
    this.riskText,
    this.avatarBg,
    this.avatarText,
    this.onTap,
  });

  final String name;
  final String initials;
  final String lastScreening;
  final String riskLabel;
  final Color? riskBg;
  final Color? riskText;
  final Color? avatarBg;
  final Color? avatarText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);
    final pillBg = riskBg ?? _defaultRiskBg();
    final pillFg = riskText ?? _defaultRiskFg();
    final aBg = avatarBg ?? ff.primaryContainer;
    final aFg = avatarText ?? ff.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: ff.secondaryBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ff.alternate, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: aBg,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: aFg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + last screening
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ff.primaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastScreening,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: ff.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Risk pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    riskLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: pillFg,
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

  Color _defaultRiskBg() {
    final rl = riskLabel.toLowerCase();
    if (rl.contains('high')) return AppColors.riskHighSurface;
    if (rl.contains('mod') || rl.contains('medium')) return AppColors.riskMediumSurface;
    return AppColors.riskLowSurface;
  }

  Color _defaultRiskFg() {
    final rl = riskLabel.toLowerCase();
    if (rl.contains('high')) return AppColors.riskHigh;
    if (rl.contains('mod') || rl.contains('medium')) return AppColors.riskMedium;
    return AppColors.riskLow;
  }
}

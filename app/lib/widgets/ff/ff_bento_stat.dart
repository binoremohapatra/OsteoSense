import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../flutter_flow/flutter_flow_util.dart';

// ============================================================================
// FFBentoStat — production version of FlutterFlow BentoStatWidget
//
// Card layout: icon container + label (top row) → value (bottom)
// Matches FF design: 32px radius, white bg, alternate border, 24px padding
// ============================================================================

class FFBentoStat extends StatelessWidget {
  const FFBentoStat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconBg,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconBg;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);
    final bgColor = iconBg ?? ff.surfaceVariant;
    final fgColor = iconColor ?? ff.primary;

    return Container(
      decoration: BoxDecoration(
        color: ff.secondaryBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: ff.alternate, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, size: 20, color: fgColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: ff.labelMedium.fontWeight,
                      color: ff.secondaryText,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ff.primaryText,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../flutter_flow/flutter_flow_util.dart';

// ============================================================================
// FFJointCard — production version of FlutterFlow JointCardWidget
//
// Selectable card for joint selection screen.
// Selected: sage green fill + sage border + white text
// Unselected: white fill + alternate border + primaryText
// ============================================================================

class FFJointCard extends StatelessWidget {
  const FFJointCard({
    super.key,
    required this.icon,
    required this.name,
    this.subtitle = '',
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);
    final bg = selected ? ff.secondary : ff.secondaryBackground;
    final borderColor = selected ? ff.secondary : ff.alternate;
    final textColor = selected ? ff.primaryBackground : ff.primaryText;
    final subtitleColor = selected ? ff.background80 : ff.secondaryText;
    final iconBg = selected
        ? const Color(0x33FFFFFF)  // onPrimary20 equivalent
        : ff.primaryBackground;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 32, color: selected ? Colors.white : ff.primary),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.4,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                    color: subtitleColor,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../flutter_flow/flutter_flow_util.dart';

// ============================================================================
// FFNavItem — production version of FlutterFlow NavItemWidget
//
// Fixes FF bugs:
//  1. Hardcoded Icons.help → actual icon from string name
//  2. Hardcoded navigate to Dashboard → uses `target` route name
//  3. active state styling correct
// ============================================================================

class FFNavItem extends StatelessWidget {
  const FFNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.target,
    this.active = false,
  });

  final String icon;
  final String label;
  final String target;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);
    final color = active ? ff.primary : ff.secondaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.goNamed(target),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _iconFromString(icon),
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps FlutterFlow icon string names to Material IconData.
  /// FF uses string identifiers like 'dashboard_rounded', 'group_rounded', etc.
  static IconData _iconFromString(String name) {
    switch (name) {
      case 'dashboard_rounded':
        return Icons.dashboard_rounded;
      case 'dashboard_outlined':
        return Icons.dashboard_outlined;
      case 'group_rounded':
        return Icons.group_rounded;
      case 'group_outlined':
        return Icons.group_outlined;
      case 'people_rounded':
        return Icons.people_rounded;
      case 'insights_rounded':
        return Icons.insights_rounded;
      case 'insights_outlined':
        return Icons.insights_outlined;
      case 'analytics_rounded':
        return Icons.analytics_rounded;
      case 'bar_chart_rounded':
        return Icons.bar_chart_rounded;
      case 'settings_rounded':
        return Icons.settings_rounded;
      case 'settings_outlined':
        return Icons.settings_outlined;
      case 'home_rounded':
        return Icons.home_rounded;
      case 'home_outlined':
        return Icons.home_outlined;
      case 'person_rounded':
        return Icons.person_rounded;
      case 'search_rounded':
        return Icons.search_rounded;
      case 'add_rounded':
        return Icons.add_rounded;
      case 'medical_services_rounded':
        return Icons.medical_services_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}

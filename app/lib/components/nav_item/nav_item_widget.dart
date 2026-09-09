import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// NavItemWidget — bottom nav destination item with icon + label.
///
/// The [icon] is an IconData passed directly.
/// The [target] drives navigation when tapped.
class NavItemWidget extends StatefulWidget {
  const NavItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.target,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String target;
  final bool active;

  @override
  State<NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<NavItemWidget> {
  void _navigate() {
    HapticFeedback.selectionClick();
    switch (widget.target.toLowerCase()) {
      case 'dashboard':
      case 'home':
        context.go('/agent/home');
        break;
      case 'patientlist':
      case 'patients':
        // The HomeScreen manages tab state; for deep link go to home
        context.go('/agent/home');
        break;
      case 'analytics':
      case 'reports':
        context.go('/agent/home');
        break;
      case 'settings':
        context.go('/agent/home');
        break;
      default:
        context.go('/agent/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF4F6757); // AppColors.primary
    final inactiveColor = const Color(0xFF92938E); // AppColors.textMuted

    return InkWell(
      onTap: _navigate,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 24,
              color: widget.active ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: AppTypography.labelSmall.copyWith(
                color: widget.active ? activeColor : inactiveColor,
                fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

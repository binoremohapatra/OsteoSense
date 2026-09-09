import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// QuickActionWidget — circular icon button with label.
///
/// The [onTap] string is parsed and executed as navigation:
/// - `"navigate:PatientList"` → navigates to /agent/home (patients tab)
/// - `"navigate:Reports"` or `"navigate:Analytics"` → reports tab
/// - `"navigate:Screening"` or `"navigate:NewScreening"` → screening flow
/// - `"navigate:AddPatient"` → add patient route
/// - `"navigate:SelfCheck"` → symptom questionnaire
class QuickActionWidget extends StatefulWidget {
  const QuickActionWidget({
    super.key,
    Color? bg,
    this.icon,
    Color? iconColor,
    String? label,
    String? onTap,
  })  : this.bg = bg ?? const Color(0xFF4F6757),
        this.iconColor = iconColor ?? Colors.white,
        this.label = label ?? 'Action',
        this.onTap = onTap ?? '';

  final Color bg;
  final Widget? icon;
  final Color iconColor;
  final String label;
  final String onTap;

  @override
  State<QuickActionWidget> createState() => _QuickActionWidgetState();
}

class _QuickActionWidgetState extends State<QuickActionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    final action = widget.onTap.trim();
    debugPrint('QuickAction: Button clicked - Action: $action');
    if (action.isEmpty) return;

    if (action.startsWith('navigate:')) {
      final target = action.substring('navigate:'.length).toLowerCase();
      debugPrint('QuickAction: Navigating to: $target');
      _navigateTo(target);
    }
  }

  void _navigateTo(String target) {
    switch (target) {
      case 'patientlist':
      case 'patients':
        context.go('/agent/home?tab=patients');
        break;
      case 'reports':
      case 'analytics':
        // Navigate to analytics tab (index 2 in home)
        debugPrint('QuickAction: Navigating to /agent/home?tab=analytics');
        context.go('/agent/home?tab=analytics');
        break;
      case 'screening':
      case 'newscreening':
      case 'jointselection':
        context.go('/screening/symptoms');
        break;
      case 'addpatient':
      case 'addeditpatient':
        context.go('/agent/add-patient');
        break;
      case 'selfcheck':
        context.go('/screening/symptoms');
        break;
      default:
        context.go('/agent/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        _handleTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: widget.bg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.bg.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: widget.icon,
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: const Color(0xFF6F716C), // textSecondary
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

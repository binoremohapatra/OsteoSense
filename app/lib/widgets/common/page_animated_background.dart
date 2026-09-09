import 'package:flutter/material.dart';

/// Subtle page-specific animated GIF background.
///
/// Placed behind existing UI as a non-interactive layer. Opacity is kept
/// low so cards, text and controls remain the visual focus.
class PageAnimatedBackground extends StatelessWidget {
  /// Asset path, e.g. `'assets/images/03_dashboard.gif'`.
  final String asset;

  /// How strongly the animation shows through. Dashboard stays extra subtle.
  final double opacity;

  const PageAnimatedBackground({
    super.key,
    required this.asset,
    this.opacity = 0.22,
  });

  /// Onboarding
  static const onboarding = 'assets/images/01_onboarding.gif';

  /// Login / Authentication
  static const authentication = 'assets/images/02_authentication.gif';

  /// Dashboard / Home
  static const dashboard = 'assets/images/03_dashboard.gif';

  /// Patient list
  static const patientList = 'assets/images/04_patient_list.gif';

  /// Joint / symptom selection
  static const jointSelection = 'assets/images/05_joint_selection.gif';

  /// Gait test
  static const gaitTest = 'assets/images/06_gait_test.gif';

  /// Risk result
  static const riskResult = 'assets/images/07_risk_result.gif';

  /// Detailed report
  static const detailedReport = 'assets/images/08_detailed_report.gif';

  /// Analytics / reports
  static const analytics = 'assets/images/09_analytics.gif';

  /// App shell (used only if a dedicated shell background is needed)
  static const appShell = 'assets/images/10_app_shell.gif';

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

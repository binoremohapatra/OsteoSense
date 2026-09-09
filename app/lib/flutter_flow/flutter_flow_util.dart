import 'package:flutter/material.dart';

// ============================================================================
// FlutterFlowTheme — production shim that maps FF token names to JointSaathi
// design system colors. All values align with app_colors.dart.
// ============================================================================
class FlutterFlowTheme {
  FlutterFlowTheme._();

  static FlutterFlowTheme of(BuildContext context) {
    return FlutterFlowTheme._();
  }

  // JointSaathi Color System — forest green, sage, dusty rose, warm off-white
  Color get primary => const Color(0xFF4F6757);           // Forest Green
  Color get primaryBackground => const Color(0xFFF7F5F0); // Warm off-white page
  Color get secondaryBackground => const Color(0xFFFFFFFF); // Card white
  Color get primaryText => const Color(0xFF2F302E);         // Dark charcoal
  Color get secondaryText => const Color(0xFF6F716C);       // Muted gray
  Color get alternate => const Color(0xFFE5E2DB);           // Soft border
  Color get error => const Color(0xFFB87070);               // Dusty rose error
  Color get success => const Color(0xFF7A9E82);             // Sage green success
  Color get warning => const Color(0xFFC4A252);             // Warm amber warning
  Color get info => const Color(0xFF7A94A8);                // Soft blue info
  Color get surface80 => const Color(0xCCF7F5F0);          // 80% page bg (glassmorphic)
  Color get surface60 => const Color(0x99F7F5F0);          // 60% page bg
  Color get surfaceVariant => const Color(0xFFD4DFCF);      // Sage light
  Color get surfaceVariant15 => const Color(0x26A8B6A0);
  Color get tertiary => const Color(0xFFD3A0A0);            // Dusty rose
  Color get secondary => const Color(0xFFA8B6A0);           // Sage
  Color get onPrimary => const Color(0xFFFFFFFF);
  Color get onSurface => const Color(0xFF2F302E);
  Color get onSurfaceVariant => const Color(0xFF34483D);    // Dark forest
  Color get onBackground => const Color(0xFF2F302E);
  Color get onBackground80 => const Color(0xCC2F302E);
  Color get onBackground10 => const Color(0x1A2F302E);
  Color get onAccent => const Color(0xFFFFFFFF);
  Color get onSecondary => const Color(0xFF2F302E);
  Color get onSecondaryContainer => const Color(0xFF34483D);
  Color get primary10 => const Color(0x1A4F6757);
  Color get primary20 => const Color(0x334F6757);
  Color get primary30 => const Color(0x4D4F6757);
  Color get primary5 => const Color(0x0D4F6757);
  Color get secondary10 => const Color(0x1AA8B6A0);
  Color get secondary20 => const Color(0x33A8B6A0);
  Color get secondary30 => const Color(0x4DA8B6A0);
  Color get secondary40 => const Color(0x66A8B6A0);
  Color get tertiary10 => const Color(0x1AD3A0A0);
  Color get tertiary30 => const Color(0x4DD3A0A0);
  Color get accent3 => const Color(0xFFE9DFC9);             // Warm beige
  Color get primaryContainer => const Color(0xFFEBF0EC);    // Forest surface
  Color get secondaryContainer => const Color(0xFFD4DFCF);  // Sage light
  Color get onPrimaryContainer => const Color(0xFF34483D);  // Dark forest
  Color get onPrimaryContainer10 => const Color(0x1A34483D);
  Color get warning15 => const Color(0x26C4A252);
  Color get success15 => const Color(0x267A9E82);
  Color get background0 => const Color(0xFFF7F5F0);
  // Additional tokens used by components
  Color get onPrimary10 => const Color(0x1AFFFFFF); // 10% white on primary
  Color get onPrimary20 => const Color(0x33FFFFFF); // 20% white on primary
  Color get softBorder => const Color(0xFFE5E2DB);
  Color get background80 => const Color(0xCCF7F5F0); // 80% page background (used by JointCard)

  TextStyle get titleSmall => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
      );

  TextStyle get headlineMedium => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.3,
      );

  TextStyle get headlineSmall => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.35,
      );

  TextStyle get headlineLarge => const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.25,
      );

  TextStyle get titleLarge => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.4,
      );

  TextStyle get titleMedium => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.4,
      );

  TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.6,
      );

  TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  TextStyle get labelLarge => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  TextStyle get labelMedium => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  TextStyle get labelSmall => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );
}

// ============================================================================
// Utility functions (FlutterFlow compat shims)
// ============================================================================

Widget safeSetState(VoidCallback callback) {
  callback();
  return const SizedBox.shrink();
}

T valueOrDefault<T>(T value, T defaultValue) {
  return value ?? defaultValue;
}

// ============================================================================
// Extension: List<Widget>.divide — inserts a separator between items.
// Used extensively in FF-generated code. Equivalent to
// list.expand((w) => [w, separator]).toList()..removeLast()
// ============================================================================
extension ListDivideExtension on List<Widget> {
  List<Widget> divide(Widget separator) {
    if (isEmpty) return this;
    final result = <Widget>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator);
    }
    return result;
  }
}

// ============================================================================
// Extension: TextStyle.override — merges TextStyle properties selectively.
// In FlutterFlow generated code, .override() is called to apply per-use
// color/weight overrides without replacing the base style entirely.
// ============================================================================
extension TextStyleOverrideExtension on TextStyle {
  TextStyle override({
    TextStyle? font,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? lineHeight,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return copyWith(
      fontFamily: font?.fontFamily ?? fontFamily,
      color: color,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      letterSpacing: letterSpacing,
      height: lineHeight ?? height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }
}

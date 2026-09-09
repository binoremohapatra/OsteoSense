import 'package:flutter/material.dart';

/// JointSaathi Centralized Color System
/// ======================================
/// All color values are defined here. Do NOT scatter Color(...) literals
/// across components — always reference these tokens.
///
/// Design Language: CALM · CLINICAL · PREMIUM · MODERN · TRUSTWORTHY
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ========================================================================
  // PRIMARY FOREST GREEN — Main brand color
  // ========================================================================
  /// Primary forest green — primary CTA, active states, chart lines, icons
  static const Color primary = Color(0xFF4F6757);

  /// Dark forest — headings, high-emphasis text, important labels
  static const Color primaryDark = Color(0xFF34483D);

  /// Light forest — hover states, soft backgrounds
  static const Color primaryLight = Color(0xFF6B8A72);

  /// Primary surface — extremely subtle tinted bg for cards/chips
  static const Color primarySurface = Color(0xFFEBF0EC);

  // ========================================================================
  // SAGE GREEN — Secondary accent
  // ========================================================================
  /// Sage — secondary accents, selected backgrounds, chart segments, indicators
  static const Color sage = Color(0xFFA8B6A0);

  /// Sage light — hover/selected background
  static const Color sageLight = Color(0xFFD4DFCF);

  /// Sage surface — very soft sage for backgrounds
  static const Color sageSurface = Color(0xFFF0F4EE);

  // ========================================================================
  // DUSTY ROSE — Attention / high-risk accent
  // ========================================================================
  /// Dusty rose — high-risk accents, attention states, secondary chart segments
  static const Color dustyRose = Color(0xFFD3A0A0);

  /// Dusty rose light — soft rose for backgrounds
  static const Color dustyRoseLight = Color(0xFFEDD0D0);

  /// Dusty rose surface — very soft rose for card backgrounds
  static const Color dustyRoseSurface = Color(0xFFF8EDEC);

  // ========================================================================
  // WARM BEIGE — Medical neutral
  // ========================================================================
  /// Warm beige — soft medical/neutral accents, moderate risk, secondary surfaces
  static const Color warmBeige = Color(0xFFE9DFC9);

  /// Warm beige dark — stronger beige for borders, text
  static const Color warmBeigeDark = Color(0xFFCCBE9E);

  /// Warm beige surface — near-white warm surface
  static const Color warmBeigeSurface = Color(0xFFF5F0E6);

  // ========================================================================
  // BACKGROUNDS & SURFACES
  // ========================================================================
  /// Page background — warm off-white, used consistently on all screens
  static const Color background = Color(0xFFF7F5F0);

  /// Card background — pure white
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface variant — slightly warmer than white, for nested cards
  static const Color surfaceVariant = Color(0xFFF3F1EC);

  /// Dark mode backgrounds
  static const Color backgroundDark = Color(0xFF0F1512);
  static const Color surfaceDark = Color(0xFF1A231D);
  static const Color surfaceVariantDark = Color(0xFF243029);

  // ========================================================================
  // TEXT COLORS
  // ========================================================================
  /// Primary text — dark charcoal, NOT pure black
  static const Color textPrimary = Color(0xFF2F302E);

  /// Secondary text — muted mid-tone
  static const Color textSecondary = Color(0xFF6F716C);

  /// Muted text — captions, metadata
  static const Color textMuted = Color(0xFF92938E);

  /// Hint text — placeholder level
  static const Color textHint = Color(0xFFB8BAB5);

  /// Dark mode text
  static const Color textPrimaryDark = Color(0xFFF0EFE9);
  static const Color textSecondaryDark = Color(0xFFA8AAA4);

  // ========================================================================
  // BORDERS & DIVIDERS
  // ========================================================================
  /// Soft border — 1px borders on cards, inputs
  static const Color softBorder = Color(0xFFE5E2DB);

  /// Border — slightly more visible
  static const Color border = Color(0xFFDDDAD3);

  /// Divider
  static const Color divider = Color(0xFFEAE7E0);

  /// Dark mode borders
  static const Color borderDark = Color(0xFF3A4540);
  static const Color dividerDark = Color(0xFF2E3A34);

  // ========================================================================
  // RISK LEVEL COLORS — Muted, semantic
  // ========================================================================
  /// Low risk — muted sage/green
  static const Color riskLow = Color(0xFF7A9E82);
  static const Color riskLowLight = Color(0xFF9DBF99);
  static const Color riskLowDark = Color(0xFF5A7D62);
  static const Color riskLowSurface = Color(0xFFECF3EC);

  /// Moderate risk — muted warm amber/beige
  static const Color riskMedium = Color(0xFFC4A252);
  static const Color riskMediumLight = Color(0xFFD4B76A);
  static const Color riskMediumDark = Color(0xFFA88A3A);
  static const Color riskMediumSurface = Color(0xFFF8F2E4);

  /// High risk — muted dusty rose
  static const Color riskHigh = Color(0xFFB87070);
  static const Color riskHighLight = Color(0xFFD3A0A0);
  static const Color riskHighDark = Color(0xFF9A5555);
  static const Color riskHighSurface = Color(0xFFF5EBEB);

  // ========================================================================
  // STATUS COLORS
  // ========================================================================
  static const Color success = Color(0xFF7A9E82);
  static const Color warning = Color(0xFFC4A252);
  static const Color error = Color(0xFFB87070);
  static const Color info = Color(0xFF7A94A8);

  // ========================================================================
  // SHADOWS — Extremely subtle
  // ========================================================================
  static const Color shadow = Color(0x08000000);
  static const Color shadowSoft = Color(0x0C2F302E);
  static const Color shadowMedium = Color(0x142F302E);

  // ========================================================================
  // CHART PALETTE — Consistent across all charts
  // Forest → Sage → Dusty Rose → Warm Beige → Soft Gray
  // ========================================================================
  static const List<Color> chartPalette = [
    Color(0xFF4F6757), // Forest
    Color(0xFFA8B6A0), // Sage
    Color(0xFFD3A0A0), // Dusty Rose
    Color(0xFFE9DFC9), // Warm Beige
    Color(0xFFB0B5AD), // Soft Gray
  ];

  static const Color chartForest = Color(0xFF4F6757);
  static const Color chartSage = Color(0xFFA8B6A0);
  static const Color chartDustyRose = Color(0xFFD3A0A0);
  static const Color chartBeige = Color(0xFFE9DFC9);
  static const Color chartGray = Color(0xFFB0B5AD);

  // ========================================================================
  // GLASS / OVERLAY
  // ========================================================================
  static const Color glassWhite = Color(0x18FFFFFF);
  static const Color glassBorder = Color(0x28FFFFFF);

  // ========================================================================
  // GRADIENTS — Subtle, restrained
  // ========================================================================

  /// Primary forest gradient — used for Weekly Goal card, FAB, primary buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5A7460), Color(0xFF34483D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Sage gradient — soft secondary surfaces
  static const LinearGradient sageGradient = LinearGradient(
    colors: [Color(0xFFD4DFCF), Color(0xFFA8B6A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Risk Low gradient
  static const LinearGradient riskLowGradient = LinearGradient(
    colors: [Color(0xFF9DBF99), Color(0xFF7A9E82)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Risk Medium gradient
  static const LinearGradient riskMediumGradient = LinearGradient(
    colors: [Color(0xFFD4B76A), Color(0xFFC4A252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Risk High gradient
  static const LinearGradient riskHighGradient = LinearGradient(
    colors: [Color(0xFFD3A0A0), Color(0xFFB87070)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========================================================================
  // LEGACY ALIASES — kept for backward compatibility during migration
  // These map old names to new JointSaathi tokens
  // ========================================================================

  /// @deprecated Use [primary] instead
  static const Color accent = Color(0xFFD3A0A0); // mapped to dusty rose
  static const Color accentLight = Color(0xFFEDD0D0);
  static const Color accentDark = Color(0xFFB87070);

  // Legacy alias — used by existing code
  static const Color textTertiary = textMuted;
  // primarySurface already defined above (line 26)

  /// fullPrimaryGradient — 3-stop gradient used by some premium buttons
  static const LinearGradient fullPrimaryGradient = LinearGradient(
    colors: [Color(0xFF6B8A72), Color(0xFF4F6757), Color(0xFF34483D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// analyticsGradient, careGradient — legacy aliases
  static const LinearGradient analyticsGradient = primaryGradient;
  static const LinearGradient careGradient = primaryGradient;
  static const LinearGradient trustGradient = LinearGradient(
    colors: [Color(0xFF34483D), Color(0xFF4F6757)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy gradient aliases mapped to JointSaathi equivalents
  static const LinearGradient successGradient = riskLowGradient;
  static const LinearGradient warningGradient = riskMediumGradient;
  static const LinearGradient alertGradient = riskHighGradient;
  static const LinearGradient onboardingGradient1 = LinearGradient(
    colors: [Color(0xFFF0F4EE), Color(0xFFD4DFCF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient onboardingGradient2 = LinearGradient(
    colors: [Color(0xFFF5F0E6), Color(0xFFE9DFC9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient onboardingGradient3 = LinearGradient(
    colors: [Color(0xFFF8EDEC), Color(0xFFEDD0D0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Mesh legacy
  static const Color meshPrimaryLight = Color(0x104F6757);
  static const Color meshSurfaceDark = Color(0xE61A231D);

  // Shadow legacy
  static const Color shadowLight = Color(0x06000000);
  static const Color shadowDark = Color(0x22000000);

  // Glass legacy
  static const Color glassBorderDark = Color(0x28333333);
  static const Color glassWhiteDark = Color(0x181A231D);

  /// Gray scale — for misc usage
  static const Color gray50 = Color(0xFFF7F5F0);
  static const Color gray100 = Color(0xFFF0EDE6);
  static const Color gray200 = Color(0xFFE5E2DB);
  static const Color gray300 = Color(0xFFCCCAC4);
  static const Color gray400 = Color(0xFFAAACA7);
  static const Color gray500 = Color(0xFF8A8C87);
  static const Color gray600 = Color(0xFF6F716C);
  static const Color gray700 = Color(0xFF545650);
  static const Color gray800 = Color(0xFF3A3B37);
  static const Color gray900 = Color(0xFF2F302E);

  // ========================================================================
  // MESH / AMBIENT BACKGROUNDS
  // ========================================================================
  static const Color meshPrimary = Color(0x104F6757);
  static const Color meshSage = Color(0x10A8B6A0);
  static const Color meshSurface = Color(0xE6FFFFFF);
  static const Color meshAccent = Color(0x10D3A0A0); // dusty rose mesh (legacy alias)

  // ========================================================================
  // ADDITIONAL LEGACY ALIASES
  // ========================================================================
  // Dark text hints (for dark mode)
  static const Color textHintDark = Color(0xFF4A4C48);

  // Accent gradient (dusty rose gradient — legacy alias)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFEDD0D0), Color(0xFFD3A0A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  /// Get risk color (muted) based on level string
  static Color getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return riskHigh;
      case 'medium':
      case 'moderate':
        return riskMedium;
      case 'low':
      default:
        return riskLow;
    }
  }

  /// Get risk surface color based on level
  static Color getRiskSurfaceColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return riskHighSurface;
      case 'medium':
      case 'moderate':
        return riskMediumSurface;
      case 'low':
      default:
        return riskLowSurface;
    }
  }

  /// Get risk gradient based on level
  static LinearGradient getRiskGradient(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return riskHighGradient;
      case 'medium':
      case 'moderate':
        return riskMediumGradient;
      case 'low':
      default:
        return riskLowGradient;
    }
  }

  /// Get risk border/label color
  static Color getRiskBorderColor(String riskLevel) => getRiskColor(riskLevel);

  /// Interpolate between risk colors for smooth gauges (0=low → 1=high)
  static Color lerpRiskColor(double t) {
    if (t < 0.33) {
      return Color.lerp(riskLow, riskMedium, t / 0.33)!;
    } else if (t < 0.66) {
      return Color.lerp(riskMedium, riskHigh, (t - 0.33) / 0.33)!;
    } else {
      return riskHigh;
    }
  }

  /// Chart color at index (cycles through palette)
  static Color chartColor(int index) =>
      chartPalette[index % chartPalette.length];
}
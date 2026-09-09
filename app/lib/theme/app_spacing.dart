/// JointSaathi Spacing System
/// Design Language: CALM · CLINICAL · PREMIUM · MODERN
///
/// Use the named constants — do NOT introduce ad-hoc pixel values.
/// Permitted multiples: 4, 8, 12, 16, 20, 24, 32
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // Base spacing unit (4pt grid)
  static const double unit = 4.0;

  // ========================================================================
  // SPACING SCALE — 4pt grid system
  // ========================================================================
  static const double xxs = 4.0;   // tightest
  static const double xs  = 8.0;   // inner gap
  static const double sm  = 12.0;  // tight component gap
  static const double md  = 16.0;  // standard gap
  static const double lg  = 20.0;  // loose gap
  static const double xl  = 24.0;  // section internal
  static const double xxl = 32.0;  // section gap
  static const double xxxl = 40.0; // page section gap

  // ========================================================================
  // BORDER RADIUS — JointSaathi radius system
  // Small:10–12  Inputs:14–16  Buttons:14–18  Cards:20–26  Pills:999
  // ========================================================================
  static const double radiusXs   = 4.0;   // tags
  static const double radiusSm   = 8.0;   // small elements
  static const double radiusMd   = 12.0;  // chips, inner containers
  static const double radiusLg   = 16.0;  // inputs, buttons (spec: 14–16)
  static const double radiusXl   = 20.0;  // larger buttons (spec: 14–18)
  static const double radiusCard = 24.0;  // *** PRIMARY CARD RADIUS ***
  static const double radiusCardLg = 26.0; // large feature cards
  static const double radiusFull = 999.0; // pill-shaped controls, avatars

  // Convenience alias
  static const double borderRadius = radiusCard;

  // ========================================================================
  // ICON SIZES
  // ========================================================================
  static const double iconXs  = 16.0;
  static const double iconSm  = 20.0;
  static const double iconMd  = 24.0;
  static const double iconLg  = 32.0;
  static const double iconXl  = 40.0;
  static const double iconXxl = 48.0;

  // ========================================================================
  // AVATAR SIZES
  // ========================================================================
  static const double avatarSm = 32.0;
  static const double avatarMd = 44.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;

  // ========================================================================
  // BUTTON HEIGHTS
  // ========================================================================
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 54.0;

  // ========================================================================
  // INPUT FIELD HEIGHTS
  // ========================================================================
  static const double inputHeightSm = 44.0;
  static const double inputHeightMd = 52.0;

  // ========================================================================
  // CARD PADDING — 20–24px (spec)
  // ========================================================================
  static const double cardPaddingSm = 16.0;
  static const double cardPaddingMd = 20.0;
  static const double cardPaddingLg = 24.0;

  // ========================================================================
  // SCREEN PADDING — 20–24px consistent horizontal margin
  // ========================================================================
  static const double screenPaddingSm = 16.0; // tight
  static const double screenPaddingMd = 20.0; // standard
  static const double screenPaddingLg = 24.0; // generous

  // ========================================================================
  // SECTION GAPS — Between page sections
  // ========================================================================
  static const double sectionGap   = 24.0;
  static const double sectionGapLg = 32.0;

  // ========================================================================
  // ELEVATION (subtle)
  // ========================================================================
  static const double elevationNone = 0;
  static const double elevationSm   = 1;
  static const double elevationMd   = 2;
  static const double elevationLg   = 4;
  static const double elevationXl   = 8;

  // ========================================================================
  // ANIMATION DURATIONS
  // ========================================================================
  static const int durationFast   = 150;
  static const int durationNormal = 250;
  static const int durationSlow   = 400;
  static const int durationSlower = 600;
}
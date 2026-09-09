import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ff/ff_button.dart';

// ============================================================================
// OnboardingScreen — matches FlutterFlow OnboardingWidget exactly.
//
// Layout (Stack):
//  1. Mesh gradient background (LinearGradient approximation of FbmGradientShaderFill)
//  2. Scrollable body: Logo → Hero slide → Language selection → spacer
//  3. Bottom CTA area (page dots + "Get Started" button)
//  4. Top-right "Skip" ghost button
// ============================================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedLanguage = 'english'; // 'english' | 'hindi'

  void _proceed() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: ff.primaryBackground,
        body: Stack(
          alignment: Alignment.topLeft,
          children: [
            // Page-specific animated background (Onboarding)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.28,
                  child: Image.asset(
                    'assets/images/01_onboarding.gif',
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-1, -1),
                          end: const Alignment(1, 1),
                          colors: [
                            ff.primaryBackground,
                            ff.secondaryBackground,
                            const Color(0x4D4A5D4E),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable main content
            SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo row ──────────────────────────────────────────────
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ff.primary,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.accessibility_new_rounded,
                              color: ff.onPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'JointSaathi',
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: ff.primaryText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Hero slide ───────────────────────────────────────────
                  _OnboardingHeroSlide(ff: ff),

                  // ── Language selection ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Choose your language',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ff.primaryText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _LanguageOption(
                          label: 'English',
                          sublabel: 'Recommended for clinical use',
                          selected: _selectedLanguage == 'english',
                          onTap: () =>
                              setState(() => _selectedLanguage = 'english'),
                        ),
                        const SizedBox(height: 8),
                        _LanguageOption(
                          label: 'हिन्दी',
                          sublabel: 'Hindi - Native support',
                          selected: _selectedLanguage == 'hindi',
                          onTap: () =>
                              setState(() => _selectedLanguage = 'hindi'),
                        ),
                      ],
                    ),
                  ),

                  // Bottom spacer for CTA overlay
                  const SizedBox(height: 140),
                ],
              ),
            ),

            // ── Bottom CTA (gradient fade + dots + button) ────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      ff.primaryBackground,
                      ff.primaryBackground.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Page indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Dot(active: true, primary: ff.primary, alternate: ff.alternate),
                          const SizedBox(width: 4),
                          _Dot(active: false, primary: ff.primary, alternate: ff.alternate),
                          const SizedBox(width: 4),
                          _Dot(active: false, primary: ff.primary, alternate: ff.alternate),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Get Started button
                      FFButton(
                        content: 'Get Started',
                        variant: 'primary',
                        size: 'large',
                        fullWidth: true,
                        onTap: _proceed,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Skip button (top-right) ───────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: _proceed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ff.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero slide component ─────────────────────────────────────────────────────

class _OnboardingHeroSlide extends StatelessWidget {
  const _OnboardingHeroSlide({required this.ff});
  final FlutterFlowTheme ff;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Illustration placeholder (blob + icon)
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ff.primary.withValues(alpha: 0.08),
                  ff.secondary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: ff.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.accessibility_new_rounded,
                    size: 52,
                    color: ff.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: ff.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'AI-Powered Screening',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ff.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'Early Detection for Joint Health',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: ff.primaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            'AI-powered screening to identify osteoarthritis risk factors early in your clinical practice.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: ff.secondaryText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language option tile ─────────────────────────────────────────────────────

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? ff.primaryContainer : ff.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ff.primary : ff.alternate,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selected ? ff.primary : ff.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: ff.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: ff.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

// ── Pagination dot ───────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.primary, required this.alternate});

  final bool active;
  final Color primary;
  final Color alternate;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? primary : alternate,
        borderRadius: BorderRadius.circular(9999),
      ),
    );
  }
}

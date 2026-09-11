import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/screening_provider.dart';
import '../../providers/patient_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/common/index.dart';
import '../../widgets/premium/inputs/premium_inputs.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';
import 'gait_test_screen.dart';

class SymptomQuestionnaireScreen extends StatefulWidget {
  final int? patientId;
  final String? jointId;
  const SymptomQuestionnaireScreen({super.key, this.patientId, this.jointId});

  @override
  State<SymptomQuestionnaireScreen> createState() =>
      _SymptomQuestionnaireScreenState();
}

class _SymptomQuestionnaireScreenState
    extends State<SymptomQuestionnaireScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Q1: Pain level
  int _painLevel = 0;

  // ── Q2: Stiffness duration
  String _stiffnessDuration = 'none';

  // ── Q3: Swelling
  bool _swelling = false;

  // ── Q4: Past injury
  bool _pastInjury = false;
  final TextEditingController _injuryDetailController = TextEditingController();

  bool _isNavigating = false;

  @override
  void dispose() {
    _pageController.dispose();
    _injuryDetailController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isNavigating) return;
    if (_currentPage < 3) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: AppMotion.standard,
        curve: AppMotion.curve,
      );
    } else {
      _submitQuestionnaire();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      HapticFeedback.selectionClick();
      _pageController.previousPage(
        duration: AppMotion.standard,
        curve: AppMotion.curve,
      );
    } else {
      // If on first page, go directly to dashboard
      context.go('/agent/home');
    }
  }

  Future<void> _submitQuestionnaire() async {
    setState(() => _isNavigating = true);
    HapticFeedback.mediumImpact();

    final screeningProvider =
        context.read<ScreeningProvider>();
    final patientProvider = context.read<PatientProvider>();

    final patientId = widget.patientId ??
        patientProvider.selectedPatientId ??
        patientProvider.patients.firstOrNull?.id;

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first')),
      );
      setState(() => _isNavigating = false);
      return;
    }

    // Save draft answers to provider for use in processing screen
    screeningProvider.setDraftAnswers(
      patientId: patientId,
      jointId: widget.jointId,
      painLevel: _painLevel,
      stiffnessDuration: _stiffnessDuration,
      swelling: _swelling,
      pastInjury: _pastInjury,
      pastInjuryDetail: _injuryDetailController.text.trim(),
    );

    // Ensure the patient is set as selected so GaitTestScreen can read it
    if (patientProvider.selectedPatient?.id != patientId) {
      final patient = patientProvider.patients.where((p) => p.id == patientId).firstOrNull;
      if (patient != null) {
        await patientProvider.selectPatient(patient);
      } else {
        await patientProvider.loadPatientById(patientId);
      }
    }

    if (!mounted) return;

    context.push('/screening/gait');

    setState(() => _isNavigating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'symptom_assessment'.tr(),
        centerTitle: false,
        showBackButton: true,
        onLeadingPressed: () => context.go('/agent/home'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/agent/home'),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '${_currentPage + 1} of 4',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/05_joint_selection.gif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Column(
            children: [
          // ── Progress bar
          _buildProgressBar(),

          // ── Questions
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildQ1PainSlider(),
                _buildQ2StiffnessChips(),
                _buildQ3SwellingToggle(),
                _buildQ4PastInjury(),
              ],
            ),
          ),

          // ── Navigation buttons
          _buildNavButtons(),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingLg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.curve,
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? AppSpacing.xs : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Q1: Pain Slider
  // ─────────────────────────────────────────────────────
  Widget _buildQ1PainSlider() {
    final painColor = _painLevel <= 3
        ? AppColors.riskLow
        : _painLevel <= 6
            ? AppColors.riskMedium
            : AppColors.riskHigh;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildQuestionHeader(
            questionNumber: 'question_1'.tr(),
            question: 'question_1_text'.tr(),
            hint: 'question_1_hint'.tr(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Big pain number display
          Center(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: painColor.withValues(alpha: 0.12),
                border: Border.all(color: painColor, width: 3),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: AppMotion.fast,
                  style: AppTypography.displayLarge.copyWith(
                    color: painColor,
                    fontWeight: AppTypography.bold,
                    fontSize: 48,
                  ),
                  child: Text('$_painLevel'),
                ),
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: AppMotion.slow,
                curve: AppMotion.curveSpring,
              ),

          const SizedBox(height: AppSpacing.xl),

          // Pain labels row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('no_pain'.tr(), style: AppTypography.labelSmall.copyWith(color: AppColors.riskLow)),
              Text('moderate'.tr(), style: AppTypography.labelSmall.copyWith(color: AppColors.riskMedium)),
              Text('worst'.tr(), style: AppTypography.labelSmall.copyWith(color: AppColors.riskHigh)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Gradient slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              thumbColor: painColor,
              overlayColor: painColor.withValues(alpha: 0.2),
              activeTrackColor: painColor,
              inactiveTrackColor: AppColors.border,
              valueIndicatorColor: painColor,
              valueIndicatorTextStyle: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            child: Slider(
              value: _painLevel.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_painLevel',
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _painLevel = val.round());
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Pain description
          AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
            decoration: BoxDecoration(
              color: painColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: painColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_getPainIcon(_painLevel), color: painColor, size: 18),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _getPainDescription(_painLevel),
                    style: AppTypography.bodySmall.copyWith(color: painColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.standard).slideX(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve);
  }

  // ─────────────────────────────────────────────────────
  // Q2: Stiffness Duration Chips
  // ─────────────────────────────────────────────────────
  Widget _buildQ2StiffnessChips() {
    final options = [
      _StiffnessOption(
        value: 'none',
        label: 'no_stiffness'.tr(),
        icon: Icons.check_circle_outline,
        color: AppColors.riskLow,
      ),
      _StiffnessOption(
        value: '<30',
        label: 'less_than_30_min'.tr(),
        icon: Icons.schedule,
        color: AppColors.riskMedium,
      ),
      _StiffnessOption(
        value: '30-60',
        label: '30_60_minutes'.tr(),
        icon: Icons.timer,
        color: AppColors.riskMedium,
      ),
      _StiffnessOption(
        value: '>60',
        label: 'more_than_60_min'.tr(),
        icon: Icons.warning_amber_outlined,
        color: AppColors.riskHigh,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildQuestionHeader(
            questionNumber: 'question_2'.tr(),
            question: 'question_2_text'.tr(),
            hint: 'question_2_hint'.tr(),
          ),
          const SizedBox(height: AppSpacing.xl),

          ...options.asMap().entries.map((entry) {
            final opt = entry.value;
            final isSelected = _stiffnessDuration == opt.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _stiffnessDuration = opt.value);
                },
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.curve,
                  padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
                  decoration: BoxDecoration(
                    color: isSelected ? opt.color.withValues(alpha: 0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected ? opt.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: AppMotion.fast,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? opt.color.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(opt.icon, color: isSelected ? opt.color : AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          opt.label,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected ? opt.color : AppColors.textPrimary,
                            fontWeight: isSelected ? AppTypography.semiBold : AppTypography.regular,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: opt.color, size: 22),
                    ],
                  ),
                ).animate(delay: (entry.key * 80).ms).fadeIn(duration: AppMotion.standard).slideX(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.standard).slideX(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve);
  }

  // ─────────────────────────────────────────────────────
  // Q3: Swelling Toggle
  // ─────────────────────────────────────────────────────
  Widget _buildQ3SwellingToggle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildQuestionHeader(
            questionNumber: 'question_3'.tr(),
            question: 'question_3_text'.tr(),
            hint: 'question_3_hint'.tr(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Large animated yes/no cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _swelling = false);
                  },
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    height: 140,
                    decoration: BoxDecoration(
                      color: !_swelling ? AppColors.riskLow.withValues(alpha: 0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: !_swelling ? AppColors.riskLow : AppColors.border,
                        width: !_swelling ? 2.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: AppMotion.fast,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !_swelling ? AppColors.riskLow.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sentiment_satisfied_rounded,
                            size: 36,
                            color: !_swelling ? AppColors.riskLow : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'no_swelling'.tr(),
                          style: AppTypography.titleSmall.copyWith(
                            color: !_swelling ? AppColors.riskLow : AppColors.textSecondary,
                            fontWeight: !_swelling ? AppTypography.semiBold : AppTypography.regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _swelling = true);
                  },
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _swelling ? AppColors.riskHigh.withValues(alpha: 0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: _swelling ? AppColors.riskHigh : AppColors.border,
                        width: _swelling ? 2.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: AppMotion.fast,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _swelling ? AppColors.riskHigh.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 36,
                            color: _swelling ? AppColors.riskHigh : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'swelling_present'.tr(),
                          style: AppTypography.titleSmall.copyWith(
                            color: _swelling ? AppColors.riskHigh : AppColors.textSecondary,
                            fontWeight: _swelling ? AppTypography.semiBold : AppTypography.regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: AppMotion.slow).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: AppMotion.slow,
            curve: AppMotion.curveSpring,
          ),

          const SizedBox(height: AppSpacing.xl),
          if (_swelling)
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
              decoration: BoxDecoration(
                color: AppColors.riskHighSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.riskHigh, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'swelling_important_indicator'.tr(),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.riskHigh),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: AppMotion.standard),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.standard).slideX(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve);
  }

  // ─────────────────────────────────────────────────────
  // Q4: Past Injury toggle + detail field
  // ─────────────────────────────────────────────────────
  Widget _buildQ4PastInjury() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildQuestionHeader(
            questionNumber: 'question_4'.tr(),
            question: 'question_4_text'.tr(),
            hint: 'question_4_hint'.tr(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Toggle switch card
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _pastInjury ? AppColors.riskMedium : AppColors.border,
                width: _pastInjury ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _pastInjury ? AppColors.riskMedium.withValues(alpha: 0.12) : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.personal_injury_outlined,
                    color: _pastInjury ? AppColors.riskMedium : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'previous_injury_surgery'.tr(),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      Text(
                        _pastInjury ? 'yes_tap_add_details'.tr() : 'no_history_of_injury'.tr(),
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _pastInjury,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _pastInjury = val;
                      if (!val) _injuryDetailController.clear();
                    });
                  },
                  activeTrackColor: AppColors.riskMedium,
                ),
              ],
            ),
          ),

          // Detail field — slides in when injury is toggled on
          AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.curve,
            child: _pastInjury
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: PremiumTextField(
                      controller: _injuryDetailController,
                      label: 'describe_injury_surgery'.tr(),
                      hint: 'injury_example'.tr(),
                      keyboardType: TextInputType.multiline,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Summary card before final submission
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.summarize_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'your_answers_so_far'.tr(),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _summaryRow('pain_level'.tr(), '$_painLevel / 10'),
                _summaryRow('morning_stiffness'.tr(), _stiffnessDurationLabel()),
                _summaryRow('swelling'.tr(), _swelling ? 'yes'.tr() : 'no'.tr()),
                _summaryRow('past_injury'.tr(), _pastInjury ? 'yes'.tr() : 'no'.tr()),
              ],
            ),
          ).animate().fadeIn(duration: AppMotion.standard, delay: 200.ms),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.standard).slideX(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve);
  }

  // ─────────────────────────────────────────────────────
  // Shared helpers
  // ─────────────────────────────────────────────────────
  Widget _buildQuestionHeader({
    required String questionNumber,
    required String question,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          child: Text(
            questionNumber,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: AppTypography.semiBold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          question,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: AppTypography.semiBold,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hint,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.standard).slideY(begin: -0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve);
  }

  Widget _buildNavButtons() {
    final isLastPage = _currentPage == 3;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingLg,
        AppSpacing.md,
        AppSpacing.screenPaddingLg,
        AppSpacing.screenPaddingLg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              flex: 2,
              child: GlassButton(
                text: 'back'.tr(),
                onPressed: _prevPage,
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            flex: 3,
            child: MagneticButton(
              text: isLastPage ? 'start_gait_test'.tr() : 'next'.tr(),
              onPressed: _isNavigating ? () {} : _nextPage,
              isLoading: _isNavigating,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.semiBold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _stiffnessDurationLabel() {
    switch (_stiffnessDuration) {
      case '<30': return 'less_than_30_minutes'.tr();
      case '30-60': return '30_60_minutes_duration'.tr();
      case '>60': return 'more_than_60_minutes'.tr();
      default: return 'none'.tr();
    }
  }

  IconData _getPainIcon(int level) {
    if (level == 0) return Icons.sentiment_very_satisfied;
    if (level <= 3) return Icons.sentiment_satisfied;
    if (level <= 6) return Icons.sentiment_neutral;
    if (level <= 8) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  String _getPainDescription(int level) {
    if (level == 0) return 'no_pain_at_all'.tr();
    if (level <= 2) return 'mild_pain_barely'.tr();
    if (level <= 4) return 'moderate_pain_activities'.tr();
    if (level <= 6) return 'significant_pain_interferes'.tr();
    if (level <= 8) return 'severe_pain_concentrate'.tr();
    return 'worst_possible_pain'.tr();
  }
}

class _StiffnessOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StiffnessOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

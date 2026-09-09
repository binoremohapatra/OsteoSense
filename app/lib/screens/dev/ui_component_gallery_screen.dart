import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

// Import all the premium components
import '../../widgets/premium/cards/premium_cards.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';
import '../../widgets/premium/inputs/premium_inputs.dart';
import '../../widgets/premium/selection/premium_selection.dart';
import '../../widgets/premium/faq_feedback/premium_faq_feedback.dart';
import '../../widgets/premium/loading/premium_loading.dart';
import '../../widgets/premium/navigation/premium_navigation.dart';
import '../../widgets/premium/charts/premium_charts.dart';
import '../../widgets/premium/backgrounds/premium_backgrounds.dart';

class UIComponentGalleryScreen extends StatefulWidget {
  const UIComponentGalleryScreen({super.key});

  @override
  State<UIComponentGalleryScreen> createState() => _UIComponentGalleryScreenState();
}

class _UIComponentGalleryScreenState extends State<UIComponentGalleryScreen> {
  int _bottomNavIndex = 0;
  int _tabIndex = 0;
  bool _switchValue = true;
  String _segmentedValue = 'Day';
  String _selectedChip = 'Knee';
  List<String> _multiSelectedChips = ['Pain', 'Swelling'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Premium UI Components', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: MeshGradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildSectionHeader('Buttons'),
            _buildButtonsSection(),

            _buildSectionHeader('Cards'),
            _buildCardsSection(),

            _buildSectionHeader('Inputs & Selection'),
            _buildInputsSection(),

            _buildSectionHeader('FAQ & Feedback'),
            _buildFeedbackSection(context),

            _buildSectionHeader('Loading states'),
            _buildLoadingSection(),

            _buildSectionHeader('Navigation'),
            _buildNavigationSection(),

            _buildSectionHeader('Charts & Visualization'),
            _buildChartsSection(),
            
            const SizedBox(height: 100), // padding for bottom nav
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _bottomNavIndex,
        onTap: (i) => setState(() => _bottomNavIndex = i),
        items: const [
          NavItem(icon: Icons.home_rounded, label: 'Home'),
          NavItem(icon: Icons.people_rounded, label: 'Patients'),
          NavItem(icon: Icons.analytics_rounded, label: 'Reports'),
        ],
      ),
      floatingActionButton: FloatingNav(
        mainIcon: Icons.add,
        items: const [
          NavItem(icon: Icons.person_add, label: 'Add Patient'),
          NavItem(icon: Icons.bluetooth, label: 'Scan Sensor'),
        ],
        onTap: (index) {
          PremiumSnackbar.show(context, message: 'Floating action $index pressed', variant: DialogVariant.success);
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Container(height: 2, width: 40, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildButtonsSection() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        MagneticButton(
          text: 'Magnetic Button',
          onPressed: () {},
        ),
        GlassButton(
          text: 'Glass Button',
          onPressed: () {},
          icon: const Icon(Icons.blur_on),
        ),
        GradientButton(
          text: 'Gradient Button',
          gradient: AppColors.fullPrimaryGradient,
          onPressed: () {},
        ),
        SuccessButton(
          text: 'Success Action',
          onPressed: () {},
          icon: const Icon(Icons.check),
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Total Screenings',
                value: '1,248',
                trend: '+12% this week',
                isPositiveTrend: true,
                icon: Icons.analytics,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricCard(
                title: 'High Risk',
                value: '42',
                trend: '-2% this week',
                isPositiveTrend: true, // fewer high risk is good
                icon: Icons.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PatientCard(
          name: 'Ram Singh',
          subtitle: 'Male, 62 yrs • Last screening: 2 days ago',
          riskLevel: 'High',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        PatientCard(
          name: 'Anita Devi',
          subtitle: 'Female, 55 yrs • Last screening: 1 week ago',
          riskLevel: 'Low',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        ParallaxCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Parallax Interaction Card', style: AppTypography.titleLarge),
                SizedBox(height: AppSpacing.xs),
                Text('Hover or drag to see the 3D tilt effect.'),
              ],
            ),
          ),
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        ExpandableCard(
          title: Text('Expandable Content', style: AppTypography.titleMedium),
          content: Text('This content is hidden by default and smoothly expands down using AnimatedSize.'),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Glassmorphic Card', style: AppTypography.titleLarge),
              SizedBox(height: AppSpacing.sm),
              Text('Uses BackdropFilter for a frosted glass effect. Best placed over animated backgrounds or images.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputsSection() {
    return Column(
      children: [
        const PremiumTextField(
          label: 'Patient ID',
          hint: 'Enter 12-digit ID',
          prefixIcon: Icon(Icons.badge, color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.md),
        const SearchField(),
        const SizedBox(height: AppSpacing.md),
        Text('OTP Verification', style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xs),
        OTPField(length: 6, onCompleted: (v) {}),
        const SizedBox(height: AppSpacing.md),
        ComboBox<String>(
          items: const ['Village A', 'Village B', 'Village C'],
          itemAsString: (item) => item,
          hint: 'Select Village',
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sync offline data automatically', style: AppTypography.bodyMedium),
            AnimatedSwitch(
              value: _switchValue,
              onChanged: (v) => setState(() => _switchValue = v),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedControl<String>(
          segments: const ['Day', 'Week', 'Month'],
          currentSegment: _segmentedValue,
          onSegmentChanged: (v) => setState(() => _segmentedValue = v),
          segmentAsString: (v) => v,
        ),
        const SizedBox(height: AppSpacing.md),
        ChipSelector<String>(
          items: const ['Knee', 'Hip', 'Ankle'],
          selectedItems: [_selectedChip],
          onToggle: (v) => setState(() => _selectedChip = v),
          itemAsString: (v) => v,
        ),
        const SizedBox(height: AppSpacing.sm),
        ChipSelector<String>(
          items: const ['Pain', 'Swelling', 'Stiffness', 'Crepitus'],
          selectedItems: _multiSelectedChips,
          isMultiSelect: true,
          onToggle: (v) {
            setState(() {
              if (_multiSelectedChips.contains(v)) {
                _multiSelectedChips.remove(v);
              } else {
                _multiSelectedChips.add(v);
              }
            });
          },
          itemAsString: (v) => v,
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedFAQ(
          question: 'How does the AI assessment work?',
          answer: 'The system uses machine learning algorithms on the edge to analyze gait sensor data combined with clinical questionnaire responses to calculate an Osteoarthritis risk score.',
        ),
        AnimatedFAQ(
          question: 'Can I use this without internet?',
          answer: 'Yes, JointSaathi is designed for offline-first usage. All AI models run locally on your device, and data synchronizes when you regain connectivity.',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            ElevatedButton(
              onPressed: () => PremiumDialog.show(
                context,
                title: 'Sync Successful',
                message: 'All 42 patient records have been synced with the central server.',
                variant: DialogVariant.success,
                confirmText: 'Done',
                onConfirm: () => Navigator.pop(context),
              ),
              child: const Text('Success Dialog'),
            ),
            ElevatedButton(
              onPressed: () => PremiumDialog.show(
                context,
                title: 'Sensor Disconnected',
                message: 'The BLE connection was lost. Please move closer to the sensor.',
                variant: DialogVariant.error,
                confirmText: 'Retry',
                onConfirm: () => Navigator.pop(context),
                cancelText: 'Cancel',
                onCancel: () => Navigator.pop(context),
              ),
              child: const Text('Error Dialog'),
            ),
            ElevatedButton(
              onPressed: () => PremiumSnackbar.show(
                context,
                message: 'Patient profile updated successfully',
                variant: DialogVariant.success,
              ),
              child: const Text('Show Snackbar'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: const [
            StatusBadge(text: 'Connected', variant: DialogVariant.success),
            SizedBox(width: AppSpacing.sm),
            StatusBadge(text: 'Syncing...', variant: DialogVariant.info),
            SizedBox(width: AppSpacing.sm),
            StatusBadge(text: 'Battery Low', variant: DialogVariant.warning),
          ],
        )
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: const [
        SkeletonProfile(),
        SizedBox(height: AppSpacing.md),
        SkeletonCard(),
        SizedBox(height: AppSpacing.md),
        Center(child: PulseLoader(size: 60)),
      ],
    );
  }

  Widget _buildNavigationSection() {
    return AnimatedTabBar(
      tabs: const ['Overview', 'Vitals', 'History', 'AI Insights'],
      currentIndex: _tabIndex,
      onTap: (i) => setState(() => _tabIndex = i),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        Text('Risk Assessment Gauge', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: RiskGauge(score: 0.72, size: 250), // High Risk
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Health Trend', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.md),
        HealthTrendChart(
          spots: const [
            FlSpot(0, 30),
            FlSpot(1, 45),
            FlSpot(2, 40),
            FlSpot(3, 60),
            FlSpot(4, 55),
            FlSpot(5, 75),
            FlSpot(6, 85),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('Risk Distribution', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  RiskDistributionChart(
                    lowPercentage: 45,
                    mediumPercentage: 30,
                    highPercentage: 25,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('Activity Sparkline', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Sparkline(
                    data: const [10, 20, 15, 30, 25, 40, 35, 50, 45],
                    width: 120,
                    height: 60,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

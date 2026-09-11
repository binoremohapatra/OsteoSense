import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../../providers/patient_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _trendTab = 0; // 0=Week, 1=Month
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic>? _overallStats;
  Map<String, int>? _riskDistribution;
  List<Map<String, dynamic>>? _screeningTrends;
  Map<String, int>? _jointAffection;
  String? _populationInsights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _analyticsService.getOverallStatistics(),
        _analyticsService.getRiskDistribution(),
        _analyticsService.getScreeningTrends(period: _trendTab == 0 ? 'week' : 'month'),
        _analyticsService.getJointAffection(),
        _analyticsService.getPopulationInsights(),
      ]);

      setState(() {
        _overallStats = results[0] as Map<String, dynamic>;
        _riskDistribution = results[1] as Map<String, int>;
        _screeningTrends = results[2] as List<Map<String, dynamic>>;
        _jointAffection = results[3] as Map<String, int>;
        _populationInsights = results[4] as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/09_analytics.gif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── HEADER ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            )
          else if (_overallStats == null || (_overallStats!['totalPatients'] as int) == 0)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'No Analytics Data Available',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Start conducting screenings to see analytics',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // ─── STAT CARDS ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingLg, AppSpacing.xl,
                  AppSpacing.screenPaddingLg, 0,
                ),
                child: _buildStatCards(patientProvider)
                    .animate().fadeIn(duration: 500.ms),
              ),
            ),

            // ─── RISK DISTRIBUTION ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingLg, AppSpacing.xl,
                  AppSpacing.screenPaddingLg, 0,
                ),
                child: _buildRiskDistributionCard()
                    .animate(delay: 100.ms).fadeIn(duration: 500.ms),
              ),
            ),

            // ─── SCREENING TRENDS ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingLg, AppSpacing.xl,
                  AppSpacing.screenPaddingLg, 0,
                ),
                child: _buildScreeningTrendsCard()
                    .animate(delay: 200.ms).fadeIn(duration: 500.ms),
              ),
            ),

            // ─── JOINT AFFECTION ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingLg, AppSpacing.xl,
                  AppSpacing.screenPaddingLg, 0,
                ),
                child: _buildJointAffectionCard()
                    .animate(delay: 300.ms).fadeIn(duration: 500.ms),
              ),
            ),

            // ─── AI POPULATION INSIGHT ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingLg, AppSpacing.xl,
                  AppSpacing.screenPaddingLg, 0,
                ),
                child: _buildAIInsightCard()
                    .animate(delay: 400.ms).fadeIn(duration: 500.ms),
              ),
            ),

            // ─── EXPORT BUTTON ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingLg, AppSpacing.xl,
                  AppSpacing.screenPaddingLg, 0,
                ),
                child: _buildExportButton()
                    .animate(delay: 500.ms).fadeIn(duration: 500.ms),
              ),
            ),
          ],

          // Bottom nav padding
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingLg,
        MediaQuery.of(context).padding.top + AppSpacing.md,
        AppSpacing.screenPaddingLg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analytics for rural health monitoring',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Filter button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.softBorder),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STAT CARDS — Total Patients + High Risk
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatCards(PatientProvider patientProvider) {
    final totalPatients = patientProvider.patients.length;
    final highRiskCount = _overallStats?['highRiskCount'] ?? 0;
    final weeklyScreenings = _overallStats?['weeklyScreenings'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _AnalyticsStatCard(
            label: 'Total Patients',
            value: totalPatients > 0 ? '$totalPatients' : '0',
            subtitle: '$weeklyScreenings screenings this week',
            icon: Icons.people_alt_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySurface,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _AnalyticsStatCard(
            label: 'High Risk',
            value: highRiskCount > 0 ? '$highRiskCount' : '0',
            subtitle: '${totalPatients > 0 ? ((highRiskCount / totalPatients) * 100).toStringAsFixed(1) : '0.0'}% of total',
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.dustyRose,
            iconBg: AppColors.dustyRoseSurface,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RISK DISTRIBUTION DONUT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRiskDistributionCard() {
    final low = _riskDistribution?['low'] ?? 0;
    final medium = _riskDistribution?['medium'] ?? 0;
    final high = _riskDistribution?['high'] ?? 0;
    final riskTotal = low + medium + high;

    // Use real data only - no demo values
    final displayLow = low;
    final displayMedium = medium;
    final displayHigh = high;

    return _JointSaathiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Risk Distribution',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    )),
                  const SizedBox(height: 3),
                  Text('Current screening cohort',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    )),
                ],
              ),
              Icon(Icons.donut_large_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (riskTotal == 0)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'No risk data available',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: displayLow.toDouble(),
                      color: AppColors.chartForest,
                      radius: 52,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: displayMedium.toDouble(),
                      color: AppColors.chartSage,
                      radius: 52,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: displayHigh.toDouble(),
                      color: AppColors.chartDustyRose,
                      radius: 52,
                      title: '',
                    ),
                  ],
                  centerSpaceRadius: 44,
                  sectionsSpace: 3,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Legend
          if (riskTotal > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppColors.chartForest, label: 'Low Risk'),
                const SizedBox(width: AppSpacing.md),
                _LegendDot(color: AppColors.chartSage, label: 'Moderate'),
                const SizedBox(width: AppSpacing.md),
                _LegendDot(color: AppColors.chartDustyRose, label: 'High Risk'),
              ],
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREENING TRENDS LINE CHART
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScreeningTrendsCard() {
    // Use real data from analytics service only
    final trendsData = _screeningTrends ?? [];
    
    // Convert to FlSpot format
    final chartSpots = trendsData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['count'] as int).toDouble(),
      );
    }).toList();

    // Use real data only - no demo values
    final displaySpots = chartSpots;

    // Generate labels from dates
    final dateLabels = trendsData.map((data) {
      final dateStr = data['date'] as String;
      final date = DateTime.parse(dateStr);
      return '${date.day}';
    }).toList();

    final finalLabels = dateLabels;

    return _JointSaathiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Screening Trends',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    )),
                  const SizedBox(height: 3),
                  Text('Weekly assessments performed',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary, fontSize: 12,
                    )),
                ],
              ),
              // Week / Month segmented control
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TrendToggle(
                      label: 'Week',
                      selected: _trendTab == 0,
                      onTap: () {
                        setState(() => _trendTab = 0);
                        _loadAnalyticsData();
                      },
                    ),
                    _TrendToggle(
                      label: 'Month',
                      selected: _trendTab == 1,
                      onTap: () {
                        setState(() => _trendTab = 1);
                        _loadAnalyticsData();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (displaySpots.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'No screening trends data',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: AppColors.softBorder,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= finalLabels.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              finalLabels[idx],
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: displaySpots,
                      isCurved: true,
                      color: AppColors.chartForest,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.chartForest,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.chartForest.withValues(alpha: 0.12),
                            AppColors.chartForest.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: (displaySpots.length - 1).toDouble().clamp(0, 6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // JOINT AFFECTION DONUT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildJointAffectionCard() {
    final knee = _jointAffection?['knee'] ?? 0;
    final hip = _jointAffection?['hip'] ?? 0;
    final ankle = _jointAffection?['ankle'] ?? 0;
    final shoulder = _jointAffection?['shoulder'] ?? 0;
    final elbow = _jointAffection?['elbow'] ?? 0;
    final wrist = _jointAffection?['wrist'] ?? 0;
    final other = _jointAffection?['other'] ?? 0;
    final jointTotal = knee + hip + ankle + shoulder + elbow + wrist + other;

    // Use real data only - no demo values
    final displayKnee = knee;
    final displayHip = hip;
    final displayAnkle = ankle;
    final displayShoulder = shoulder;
    final displayElbow = elbow;
    final displayWrist = wrist;
    final displayOther = other;

    return _JointSaathiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Joint Affection',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            )),
          const SizedBox(height: AppSpacing.xl),
          if (jointTotal == 0)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.accessibility_new,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'No joint affection data',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (displayKnee > 0)
                      PieChartSectionData(
                        value: displayKnee.toDouble(), color: AppColors.chartForest,
                        radius: 52, title: '',
                      ),
                    if (displayHip > 0)
                      PieChartSectionData(
                        value: displayHip.toDouble(), color: AppColors.chartSage,
                        radius: 52, title: '',
                      ),
                    if (displayAnkle > 0)
                      PieChartSectionData(
                        value: displayAnkle.toDouble(), color: AppColors.chartDustyRose,
                        radius: 52, title: '',
                      ),
                    if (displayShoulder > 0)
                      PieChartSectionData(
                        value: displayShoulder.toDouble(), color: Colors.blue,
                        radius: 52, title: '',
                      ),
                    if (displayElbow > 0)
                      PieChartSectionData(
                        value: displayElbow.toDouble(), color: Colors.purple,
                        radius: 52, title: '',
                      ),
                    if (displayWrist > 0)
                      PieChartSectionData(
                        value: displayWrist.toDouble(), color: Colors.orange,
                        radius: 52, title: '',
                      ),
                    if (displayOther > 0)
                      PieChartSectionData(
                        value: displayOther.toDouble(), color: AppColors.chartBeige,
                        radius: 52, title: '',
                      ),
                  ],
                  centerSpaceRadius: 44,
                  sectionsSpace: 3,
                ),
              ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (jointTotal > 0)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (displayKnee > 0) _LegendDot(color: AppColors.chartForest, label: 'Knee'),
                if (displayHip > 0) _LegendDot(color: AppColors.chartSage, label: 'Hip'),
                if (displayAnkle > 0) _LegendDot(color: AppColors.chartDustyRose, label: 'Ankle'),
                if (displayShoulder > 0) _LegendDot(color: Colors.blue, label: 'Shoulder'),
                if (displayElbow > 0) _LegendDot(color: Colors.purple, label: 'Elbow'),
                if (displayWrist > 0) _LegendDot(color: Colors.orange, label: 'Wrist'),
                if (displayOther > 0) _LegendDot(color: AppColors.chartBeige, label: 'Other'),
              ],
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI POPULATION INSIGHT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAIInsightCard() {
    final insights = _populationInsights ?? 'Start conducting screenings to generate population insights.';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.softBorder),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Population Insight',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
                const SizedBox(height: 4),
                Text(
                  insights,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXPORT BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildExportButton() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final csvData = await _analyticsService.exportAnalytics(format: 'csv');
        // TODO: Implement file download/sharing functionality
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(csvData.contains('Error') ? 'Export failed' : 'Export ready (implementation needed)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: AppSpacing.buttonHeightMd,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.softBorder, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_outlined, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text('Export Detailed Report',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────

class _JointSaathiCard extends StatelessWidget {
  final Widget child;
  const _JointSaathiCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.softBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      child: child,
    );
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _AnalyticsStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.5,
            )),
          const SizedBox(height: 4),
          Text(subtitle,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.riskLow,
              fontSize: 11,
            )),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          )),
      ],
    );
  }
}

class _TrendToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TrendToggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: selected ? [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ] : [],
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

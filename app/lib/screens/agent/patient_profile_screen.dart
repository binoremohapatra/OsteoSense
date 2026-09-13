import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/screening.dart';
import '../../providers/patient_provider.dart';
import '../../providers/screening_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/index.dart';
import '../../widgets/common/pulsing_dot.dart';
import '../../widgets/premium/cards/premium_cards.dart';
import '../../widgets/premium/charts/premium_charts.dart';
import 'edit_patient_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  final int patientId;

  const PatientProfileScreen({super.key, required this.patientId});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final screeningProvider = Provider.of<ScreeningProvider>(context, listen: false);

    await patientProvider.loadPatientById(widget.patientId);
    await screeningProvider.loadScreeningsByPatient(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);
    final screeningProvider = Provider.of<ScreeningProvider>(context);
    final patient = patientProvider.selectedPatient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'patient_details'.tr(),
        centerTitle: false,
        showBackButton: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/agent/patients'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            onPressed: () {
              if (patient != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditPatientScreen(patient: patient)),
                ).then((updatedPatient) {
                  if (updatedPatient != null) {
                    _loadData();
                  }
                });
              }
            },
          ),
        ],
      ),
      body: patientProvider.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'loading_patient_profile'.tr(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : patient == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'patient_not_found'.tr(),
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CustomButton(
                        text: 'go_back'.tr(),
                        onPressed: () => Navigator.pop(context),
                        variant: ButtonVariant.primary,
                        size: ButtonSize.medium,
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header card with patient info
                        _buildPatientHeader(patient).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                        const SizedBox(height: AppSpacing.xl),

                        // Risk Gauge
                        if (screeningProvider.screenings.isNotEmpty) ...[
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'current_risk_level'.tr(),
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                RiskGauge(
                                  score: screeningProvider.screenings.first.confidence ?? 0.0,
                                  size: 240,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 100.ms).scale(curve: Curves.easeOutCubic),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        // Patient details using MetricCards
                        Text(
                          'patient_metrics'.tr(),
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                        const SizedBox(height: AppSpacing.md),
                        _buildPatientMetrics(patient)
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 200.ms),
                        const SizedBox(height: AppSpacing.xl),

                        // Screening history
                        Text(
                          'screening_timeline'.tr(),
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
                        const SizedBox(height: AppSpacing.md),
                        _buildScreeningHistory(screeningProvider.screenings)
                            .animate()
                            .fadeIn(duration: 300.ms, delay: 250.ms),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _buildPatientHeader(patient) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      child: Row(
        children: [
          Hero(
            tag: 'avatar_${patient.id}',
            child: GradientAvatar(
              name: patient.name,
              size: 80,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const PulsingDot(color: Colors.green),
                    const SizedBox(width: AppSpacing.xs),
                    Text('active'.tr(), style: AppTypography.bodySmall.copyWith(
                      color: Colors.green, fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '${patient.age} ${'years'.tr()} • ${patient.gender}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (patient.village != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: AppSpacing.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          patient.village!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientMetrics(patient) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.8,
      children: [
        MetricCard(
          title: 'age'.tr(),
          value: '${patient.age}',
          icon: Icons.cake_rounded,
        ),
        MetricCard(
          title: 'gender'.tr(),
          value: patient.gender.substring(0, 1).toUpperCase() + patient.gender.substring(1),
          icon: Icons.person_rounded,
        ),
        MetricCard(
          title: 'height'.tr(),
          value: patient.heightCm != null ? '${patient.heightCm!.toStringAsFixed(0)} ${'cm'.tr()}' : '--',
          icon: Icons.height_rounded,
        ),
        MetricCard(
          title: 'weight'.tr(),
          value: patient.weightKg != null ? '${patient.weightKg!.toStringAsFixed(1)} ${'kg'.tr()}' : '--',
          icon: Icons.monitor_weight_rounded,
        ),
      ],
    );
  }


  Widget _buildScreeningHistory(List<Screening> screenings) {
    if (screenings.isEmpty) {
      return CustomCard(
        variant: CardVariant.elevated,
        padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
        child: Column(
          children: [
            const Icon(
              Icons.assignment,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'no_screenings_yet'.tr(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(
        screenings.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildScreeningTimelineItem(screenings[index], index),
        ),
      ),
    );
  }

  Widget _buildScreeningTimelineItem(Screening screening, int index) {
    final riskColor = AppColors.getRiskColor(screening.riskLevel ?? 'low');
    final isLast = index == 0; // Most recent first

    return CustomCard(
      variant: screening.riskLevel == 'high'
          ? CardVariant.riskHigh
          : screening.riskLevel == 'medium'
              ? CardVariant.riskMedium
              : CardVariant.riskLow,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: riskColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (isLast)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: riskColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.3, 1.3),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),

          // Screening details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(screening.screeningDate),
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getRiskSurfaceColor(screening.riskLevel ?? 'low'),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '${((screening.confidence ?? 0.0) * 100).toInt()}%',
                        style: AppTypography.labelSmall.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '${'risk_level_colon'.tr()} ${(screening.riskLevel ?? 'low').toUpperCase()}',
                      style: AppTypography.bodySmall.copyWith(
                        color: riskColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (screening.jointId != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '•',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        screening.jointId!.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (screening.contributingFactors != null &&
                    screening.contributingFactors!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${'factors_colon'.tr()} ${screening.contributingFactors!.replaceAll(',', ', ')}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // View details arrow
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    ).animate().slideX(
      begin: -0.2,
      end: 0,
      duration: 300.ms,
      delay: Duration(milliseconds: 50 * index),
      curve: Curves.easeOut,
    );
  }
}

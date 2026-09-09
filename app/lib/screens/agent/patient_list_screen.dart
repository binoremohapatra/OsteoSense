import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/patient_provider.dart';
import '../../models/patient.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/common/index.dart';
import '../../widgets/premium/inputs/premium_inputs.dart';
import '../../widgets/premium/loading/premium_loading.dart';
import '../../widgets/premium/cards/premium_cards.dart';
import 'add_patient_screen.dart';
import 'patient_profile_screen.dart';
import '../../widgets/common/open_container_card.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterRisk = 'all';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Load patients after first frame so Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientProvider>(context, listen: false).loadPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Patients',
        centerTitle: false,
        showBackButton: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/agent/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  'assets/images/04_patient_list.gif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Column(
            children: [
          // Search bar with animation
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPaddingLg, AppSpacing.screenPaddingLg, AppSpacing.screenPaddingLg, 0),
            child: SearchField(
              controller: _searchController,
              hint: 'Search patients by name or village',
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  patientProvider.loadPatients();
                } else {
                  patientProvider.searchPatients(value);
                }
              },
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Animated filter chips
          if (_showFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingLg),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', _filterRisk == 'all'),
                  const SizedBox(width: AppSpacing.md),
                  _buildFilterChip('Low Risk', 'low', _filterRisk == 'low'),
                  const SizedBox(width: AppSpacing.md),
                  _buildFilterChip('Medium Risk', 'medium', _filterRisk == 'medium'),
                  const SizedBox(width: AppSpacing.md),
                  _buildFilterChip('High Risk', 'high', _filterRisk == 'high'),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(
              begin: -0.2,
              end: 0,
              duration: 300.ms,
            ),
          const SizedBox(height: AppSpacing.md),

          // Patient list or empty state
          Expanded(
            child: patientProvider.isLoading
                ? ListView.builder(
                    itemCount: 6,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingLg),
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: SkeletonProfile(),
                    ),
                  )
                : patientProvider.patients.isEmpty
                    ? _buildEmptyState()
                    : _buildPatientList(patientProvider),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0, duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 80), // Proper spacing for bottom nav
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterRisk = value;
          final patientProvider = Provider.of<PatientProvider>(context, listen: false);
          if (value == 'all') {
            patientProvider.loadPatients();
          } else {
            patientProvider.filterByRiskLevel(value);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.softBorder,
            width: 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.person_add_alt,
              size: 40,
              color: AppColors.primary,
            ),
          ).animate().scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.easeOut,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No Patients Yet',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap the + button to add your first patient',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 180,
            child: CustomButton(
              text: 'Add Patient',
              onPressed: () => context.go('/agent/add-patient'),
              variant: ButtonVariant.primary,
              size: ButtonSize.small,
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPatientList(PatientProvider patientProvider) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await patientProvider.loadPatients();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingLg,
          vertical: AppSpacing.md,
        ),
        itemCount: patientProvider.patients.length,
        itemBuilder: (context, index) {
          final patient = patientProvider.patients[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildPatientCard(patient)
                .animate(delay: Duration(milliseconds: index * 50))
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.05, end: 0, duration: 400.ms),
          );
        },
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    const String riskLevel = 'low'; // Screenings are fetched separately; default to low
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => context.go('/agent/patient/${patient.id}'),
        child: PatientCard(
          name: patient.name,
          subtitle: patient.village != null ? '${patient.age} yrs • ${patient.gender}\n${patient.village}' : '${patient.age} yrs • ${patient.gender}',
          riskLevel: riskLevel,
          onTap: () => context.go('/agent/patient/${patient.id}'),
        ),
      ),
    );
  }
}

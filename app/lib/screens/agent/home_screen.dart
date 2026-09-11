import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/screening_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/premium/navigation/premium_navigation.dart';
import '../../components/bento_stat/bento_stat_widget.dart';
import '../../components/patient_row/patient_row_widget.dart';
import '../../components/quick_action/quick_action_widget.dart';
import '../../services/location_service.dart';
import 'patient_list_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  GoRouter? _router; // saved reference to avoid calling of(context) in dispose()

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeDashboard(),
      const PatientListScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
    _loadData();
    
    // Listen to route changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _router = GoRouter.of(context);
      _router!.routerDelegate.addListener(_onRouteChanged);
      _handleTabFromRoute();
    });
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    _handleTabFromRoute();
  }

  void _handleTabFromRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = GoRouter.of(context);
      final uri = router.routeInformationProvider.value.uri;
      final tabParam = uri.queryParameters['tab'];
      debugPrint('HomeScreen: Route tab parameter: $tabParam, current index: $_currentIndex');
      
      if (tabParam != null) {
        switch (tabParam.toLowerCase()) {
          case 'patients':
            debugPrint('HomeScreen: Switching to patients tab (index 1)');
            if (_currentIndex != 1) {
              setState(() {
                _currentIndex = 1;
                debugPrint('HomeScreen: Changed index to 1');
              });
            }
            break;
          case 'analytics':
          case 'reports':
            debugPrint('HomeScreen: Switching to analytics tab (index 2)');
            if (_currentIndex != 2) {
              setState(() {
                _currentIndex = 2;
                debugPrint('HomeScreen: Changed index to 2');
              });
            }
            break;
          case 'settings':
            debugPrint('HomeScreen: Switching to settings tab (index 3)');
            if (_currentIndex != 3) {
              setState(() {
                _currentIndex = 3;
                debugPrint('HomeScreen: Changed index to 3');
              });
            }
            break;
          default:
            debugPrint('HomeScreen: Unknown tab, defaulting to home (index 0)');
            // Default to home tab (index 0)
            if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
                debugPrint('HomeScreen: Changed index to 0');
              });
            }
        }
      }
    });
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final patientProvider = Provider.of<PatientProvider>(context, listen: false);
        final screeningProvider = Provider.of<ScreeningProvider>(context, listen: false);
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        await patientProvider.loadPatients();
        await screeningProvider.loadScreenings();
        await settingsProvider.checkConnectivity();
        settingsProvider.startConnectivityListener();
      } catch (e) {
        debugPrint('Error loading data: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isOnline = settingsProvider.isConnected;

    return Scaffold(
      extendBody: false,
      body: RetainedTabSwitcher(
        currentIndex: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CenteredFabBottomNav(
        currentIndex: _currentIndex,
        items: const [
          CenteredNavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Home',
          ),
          CenteredNavItem(
            icon: Icons.group_outlined,
            selectedIcon: Icons.group_rounded,
            label: 'Patients',
          ),
          CenteredNavItem(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights_rounded,
            label: 'Analytics',
          ),
          CenteredNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == _currentIndex) return;
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _currentIndex = index);
        },
        onFabTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          context.go('/screening/select-patient');
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME DASHBOARD — JointSaathi Visual Design
// ═══════════════════════════════════════════════════════════════════════════

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late Future<Map<String, int>> _riskDistributionFuture;
  String _currentLocation = 'Getting location...';
  final LocationService _locationService = LocationService();

  // Method to trigger tab switch from parent
  static void navigateToAnalytics(BuildContext context) {
    debugPrint('HomeDashboard: Static method called to navigate to analytics');
    context.go('/agent/home?tab=analytics');
  }

  @override
  void initState() {
    super.initState();
    _riskDistributionFuture = Provider.of<ScreeningProvider>(context, listen: false)
        .getRiskDistribution();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentLocation = location;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Location unavailable';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final screeningProvider = Provider.of<ScreeningProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final totalPatients = patientProvider.patients.length;
    final isOnline = settingsProvider.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Page-specific animated background (Dashboard) — kept subtle so UI stays prominent
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  'assets/images/03_dashboard.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
          // ─── HEADER ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, authProvider, isOnline)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.08, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
          ),

          // ─── WEEKLY GOAL CARD ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingLg,
                AppSpacing.xl,
                AppSpacing.screenPaddingLg,
                0,
              ),
              child: _buildWeeklyGoalCard(screeningProvider)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
            ),
          ),

          // ─── 2×2 STAT CARDS ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingLg,
                AppSpacing.xl,
                AppSpacing.screenPaddingLg,
                0,
              ),
              child: FutureBuilder<Map<String, int>>(
                future: _riskDistributionFuture,
                builder: (context, snapshot) {
                  final highRisk = snapshot.data?['high'] ?? 0;
                  return _buildStatGrid(
                    context,
                    totalPatients: totalPatients,
                    highRisk: highRisk,
                    isOnline: isOnline,
                  );
                },
              ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
            ),
          ),

          // ─── QUICK ACTIONS ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingLg,
                AppSpacing.xl,
                AppSpacing.screenPaddingLg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuickActions(),
                ],
              ).animate(delay: 300.ms).fadeIn(duration: 600.ms),
            ),
          ),

          // ─── AI INSIGHT ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingLg,
                AppSpacing.xl,
                AppSpacing.screenPaddingLg,
                0,
              ),
              child: _buildAIInsightCard()
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 600.ms),
            ),
          ),

          // ─── RECENT PATIENTS ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingLg,
                AppSpacing.xl,
                AppSpacing.screenPaddingLg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader(title: 'Recent Patients'),
                      GestureDetector(
                        onTap: () => context.go('/agent/patients'),
                        child: Text(
                          'See All',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (patientProvider.patients.isEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 48,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No patients yet',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Add your first patient to get started',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...patientProvider.patients.take(3).toList().asMap().entries.map((entry) {
                      final i = entry.key;
                      final patient = entry.value;
                      final initials = patient.name
                          .split(' ')
                          .map((n) => n.isEmpty ? '' : n[0])
                          .take(2)
                          .join()
                          .toUpperCase();

                      // Assign avatar colors based on index
                      final avatarColors = [
                        const Color(0xFFE9DFC9), // warm beige
                        const Color(0xFFD4DFCF), // sage light
                        const Color(0xFFEBF0EC), // forest surface
                      ];
                      final textColors = [
                        const Color(0xFF7A6A45),
                        const Color(0xFF4F6757),
                        const Color(0xFF34483D),
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: PatientRowWidget(
                          initials: initials,
                          name: patient.name,
                          lastScreening: '${patient.age} yrs • Knee',
                          riskLabel: 'LOW RISK',
                          riskBg: AppColors.riskLowSurface,
                          riskText: AppColors.riskLow,
                          bgColor: avatarColors[i % avatarColors.length],
                          textColor: textColors[i % textColors.length],
                          patientId: patient.id?.toString(),
                        ).animate(delay: (400 + i * 80).ms)
                            .fadeIn(duration: 500.ms)
                            .slideX(begin: -0.05, end: 0, duration: 500.ms),
                      );
                    }),
                  ],
                ).animate(delay: 450.ms).fadeIn(duration: 600.ms),
              ),
            ),

          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER — Namaste, Dr. Sharma with location + avatar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AuthProvider auth, bool isOnline) {
    final name = auth.currentUser?.fullName ?? 'Health Worker';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingLg,
        MediaQuery.of(context).padding.top + AppSpacing.md,
        AppSpacing.screenPaddingLg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _currentLocation,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Avatar + sync badge (clickable - navigates to profile page)
          GestureDetector(
            onTap: () => context.go('/agent/profile'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySurface,
                    border: Border.all(color: AppColors.softBorder, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.riskLow : AppColors.textMuted,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
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
  // WEEKLY SCREENING GOAL CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWeeklyGoalCard(ScreeningProvider screeningProvider) {
    final weeklyTarget = 16;
    final completedThisWeek = screeningProvider.screenings
        .where((s) => s.screeningDate.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;
    final progressPercent = completedThisWeek / weeklyTarget;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A7460), Color(0xFF34483D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Screening Goal',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progressPercent * 100).round()}%',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 5),
              Text(
                '$completedThisWeek screenings completed this week',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2×2 STAT GRID
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatGrid(
    BuildContext context, {
    required int totalPatients,
    required int highRisk,
    required bool isOnline,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BentoStatWidget(
                icon: Icon(Icons.people_rounded, color: AppColors.primary, size: 20),
                iconBg: AppColors.primarySurface,
                label: 'Total Patient',
                value: '$totalPatients',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: BentoStatWidget(
                icon: Icon(Icons.warning_amber_rounded, color: AppColors.dustyRose, size: 20),
                iconBg: AppColors.dustyRoseSurface,
                label: 'High Risk',
                value: '$highRisk',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: BentoStatWidget(
                icon: Icon(Icons.directions_walk_rounded, color: AppColors.sage, size: 20),
                iconBg: AppColors.sageSurface,
                label: 'Screenings',
                value: '${context.read<ScreeningProvider>().screenings.length}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: BentoStatWidget(
                icon: Icon(
                  isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isOnline ? AppColors.riskLow : AppColors.textMuted,
                  size: 20,
                ),
                iconBg: isOnline ? AppColors.riskLowSurface : AppColors.surfaceVariant,
                label: 'Sync Status',
                value: isOnline ? 'Online' : 'Offline',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        QuickActionWidget(
          icon: Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
          bg: const Color(0xFF4F6757), // Forest
          label: 'New Patient',
          onTap: 'navigate:AddPatient',
        ),
        QuickActionWidget(
          icon: Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
          bg: const Color(0xFFB87070), // Dusty rose
          label: 'Screening',
          onTap: 'navigate:Screening',
        ),
        QuickActionWidget(
          icon: Icon(Icons.insights_rounded, color: Colors.white, size: 26),
          bg: const Color(0xFFA8B6A0), // Sage
          label: 'Analytics',
          onTap: 'navigate:Analytics',
        ),
        QuickActionWidget(
          icon: Icon(Icons.self_improvement_rounded, color: AppColors.textPrimary, size: 26),
          bg: const Color(0xFFE9DFC9), // Warm beige
          label: 'Self Check',
          onTap: 'navigate:SelfCheck',
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI INSIGHT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAIInsightCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.softBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Knee osteoarthritis risk has increased by 12% in your last 10 screenings. Consider focusing on gait stability exercises.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SECTION HEADER HELPER
// ─────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 17,
        letterSpacing: -0.2,
      ),
    );
  }
}

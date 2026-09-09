import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../widgets/premium/cards/premium_cards.dart';
import '../shared/preventive_care_home_screen.dart';
import '../shared/symptom_questionnaire_screen.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar Header
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go('/role');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: AppSpacing.screenPaddingLg, bottom: AppSpacing.lg),
              title: Text(
                'My Dashboard',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: AppTypography.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              ),
            ),
          ),

          // ── Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome card
                _buildWelcomeCard(context)
                    .animate()
                    .fadeIn(duration: AppMotion.standard)
                    .slideY(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),
                
                const SizedBox(height: AppSpacing.xxl),

                // Main CTA
                Text('Self Assessment', style: AppTypography.titleMedium.copyWith(fontWeight: AppTypography.semiBold)),
                const SizedBox(height: AppSpacing.md),
                _buildAssessmentCta(context)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: AppMotion.standard)
                    .slideY(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),

                const SizedBox(height: AppSpacing.xxl),

                // Preventive care access
                Text('Learn & Prevent', style: AppTypography.titleMedium.copyWith(fontWeight: AppTypography.semiBold)),
                const SizedBox(height: AppSpacing.md),
                _buildPreventiveCareCard(context)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: AppMotion.standard)
                    .slideY(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.currentUser?.fullName ?? 'User';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back!', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    Text(
                      userName,
                      style: AppTypography.titleLarge.copyWith(fontWeight: AppTypography.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ready for self-check', style: AppTypography.labelMedium.copyWith(color: AppColors.success)),
                      Text('Check your joint health today', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCta(BuildContext context) {
    return PremiumActionCard(
      title: 'Start Self-Check',
      subtitle: 'Answer a few questions & take a short walk to check your joint health.',
      icon: Icons.play_arrow_rounded,
      iconColor: AppColors.primary,
      onTap: () => context.push('/screening/symptoms', extra: 0),
    );
  }

  Widget _buildPreventiveCareCard(BuildContext context) {
    return PremiumActionCard(
      title: 'Preventive Care',
      subtitle: 'Exercises, diet tips, and habits to protect your joints.',
      icon: Icons.spa_rounded,
      iconColor: AppColors.success,
      onTap: () => context.go('/preventive-care/home'),
    );
  }
}

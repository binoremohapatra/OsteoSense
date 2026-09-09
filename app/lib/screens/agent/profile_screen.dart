import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Try to load from backend first
      // For now, use local data since backend is returning 401
      // In production, this would call API to get latest profile data
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _profileData = {
            'fullName': authProvider.currentUser?.fullName ?? 'Health Worker',
            'phoneNumber': authProvider.currentUser?.phoneNumber ?? 'Not provided',
            'healthCenterId': authProvider.currentUser?.healthCenterId ?? 'Not assigned',
            'location': authProvider.currentUser?.location ?? 'Not set',
            'role': 'Healthcare Provider',
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _profileData = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/agent/home'),
        ),
        title: Text(
          'Profile',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _profileData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Failed to load profile',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingLg,
                    AppSpacing.md,
                    AppSpacing.screenPaddingLg,
                    MediaQuery.of(context).padding.bottom + AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      _buildProfileHeader()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.1, end: 0, duration: 600.ms),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Profile Details
                      _buildProfileSection('Personal Information', [
                        _ProfileDetailItem(
                          icon: Icons.person_rounded,
                          label: 'Full Name',
                          value: _profileData!['fullName'] ?? 'Not provided',
                        ),
                        _ProfileDetailItem(
                          icon: Icons.phone_rounded,
                          label: 'Phone Number',
                          value: _profileData!['phoneNumber'] ?? 'Not provided',
                        ),
                      ]).animate(delay: 100.ms).fadeIn(duration: 600.ms),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      _buildProfileSection('Professional Information', [
                        _ProfileDetailItem(
                          icon: Icons.local_hospital_rounded,
                          label: 'Health Center ID',
                          value: _profileData!['healthCenterId'] ?? 'Not assigned',
                        ),
                        _ProfileDetailItem(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: _profileData!['location'] ?? 'Not set',
                        ),
                        _ProfileDetailItem(
                          icon: Icons.badge_rounded,
                          label: 'Role',
                          value: _profileData!['role'] ?? 'Healthcare Provider',
                        ),
                      ]).animate(delay: 200.ms).fadeIn(duration: 600.ms),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              border: Border.all(color: AppColors.softBorder, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: AppColors.primary,
              size: 56,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _profileData!['fullName'] ?? 'Health Worker',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _profileData!['role'] ?? 'Healthcare Provider',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.softBorder, width: 1),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
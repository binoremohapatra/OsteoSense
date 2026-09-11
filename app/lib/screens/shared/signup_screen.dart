import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_motion.dart';

import '../../widgets/premium/inputs/premium_inputs.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, this.role = 'agent'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _healthCenterController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _healthCenterController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final authProvider = context.read<AuthProvider>();

    final user = User(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      healthCenterId: widget.role == 'agent'
          ? (_healthCenterController.text.trim().isNotEmpty
              ? _healthCenterController.text.trim()
              : 'HC-001')
          : null,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
    );

    final success = await authProvider.signup(user);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final role = authProvider.userRole ?? widget.role;
      context.go(role == 'user' ? '/user/home' : '/agent/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Signup failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAgent = widget.role == 'agent';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top gradient banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingLg,
                  AppSpacing.xl,
                  AppSpacing.screenPaddingLg,
                  AppSpacing.xxl,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppSpacing.radiusXl),
                    bottomRight: Radius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      isAgent ? 'create_health_worker_account'.tr() : 'create_account'.tr(),
                      style: AppTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: AppTypography.bold),
                    ),
                    Text(
                      isAgent
                          ? 'health_worker_description'.tr()
                          : 'user_description'.tr(),
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                    ),
                  ],
                ).animate().fadeIn(duration: AppMotion.slow).slideY(begin: -0.1, end: 0, duration: AppMotion.slow, curve: AppMotion.curve),
              ),

              // ── Form
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      PremiumTextField(
                        controller: _nameController,
                        label: 'full_name'.tr(),
                        hint: 'enter_full_name'.tr(),
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'full_name_required'.tr();
                          return null;
                        },
                      ).animate().fadeIn(duration: AppMotion.standard, delay: 50.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),

                      const SizedBox(height: AppSpacing.md),

                      PremiumTextField(
                        controller: _phoneController,
                        label: 'phone_number'.tr(),
                        hint: 'phone_number_hint'.tr(),
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'phone_number_required'.tr();
                          if (v.length < 10) return 'valid_phone_number'.tr();
                          return null;
                        },
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      ).animate().fadeIn(duration: AppMotion.standard, delay: 100.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),

                      const SizedBox(height: AppSpacing.md),

                      PremiumTextField(
                        controller: _passwordController,
                        label: 'password'.tr(),
                        hint: 'create_password_hint'.tr(),
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textTertiary, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'password_required'.tr();
                          if (v.length < 6) return 'password_min_length'.tr();
                          return null;
                        },
                      ).animate().fadeIn(duration: AppMotion.standard, delay: 150.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),

                      if (isAgent) ...[
                        const SizedBox(height: AppSpacing.md),
                        PremiumTextField(
                          controller: _healthCenterController,
                          label: 'health_center'.tr(),
                          hint: 'health_center_hint'.tr(),
                          prefixIcon: const Icon(Icons.local_hospital_outlined),
                        ).animate().fadeIn(duration: AppMotion.standard, delay: 200.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),

                        const SizedBox(height: AppSpacing.md),
                        PremiumTextField(
                          controller: _locationController,
                          label: 'location'.tr(),
                          hint: 'operating_area_hint'.tr(),
                          prefixIcon: const Icon(Icons.location_city_outlined),
                        ).animate().fadeIn(duration: AppMotion.standard, delay: 250.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard, curve: AppMotion.curve),
                      ],

                      const SizedBox(height: AppSpacing.xxl),

                      GradientButton(
                        text: 'sign_up'.tr(),
                        onPressed: _isLoading ? () {} : _signup,
                        isLoading: _isLoading,
                        gradient: AppColors.fullPrimaryGradient,
                        fullWidth: true,
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ).animate().fadeIn(duration: AppMotion.standard, delay: 300.ms),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Login link
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text('already_have_account'.tr() + ' ', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            GestureDetector(
                              onTap: () => context.go('/login?role=${widget.role}'),
                              child: Text('login'.tr(), style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: AppTypography.semiBold)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: AppMotion.standard, delay: 350.ms),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
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
import '../../widgets/premium/buttons/premium_buttons.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _gender = 'male';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    
    final patientProvider = context.read<PatientProvider>();

    final patient = Patient(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _gender,
      contact: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      village: _villageController.text.trim().isEmpty ? null : _villageController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
      weightKg: double.tryParse(_weightController.text.trim()),
      heightCm: double.tryParse(_heightController.text.trim()),
    );

    final success = await patientProvider.addPatient(patient);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Patient added successfully'),
          ]),
          backgroundColor: AppColors.riskLow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
      context.pop(true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(patientProvider.errorMessage ?? 'Failed to add patient'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Add Patient',
        centerTitle: false,
        showBackButton: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // Check if we came from select patient screen
            final router = GoRouter.of(context);
            final previousPath = router.routeInformationProvider.value.uri.path;
            if (previousPath == '/screening/select-patient') {
              context.pop();
            } else {
              context.go('/agent/patients');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
          children: [
            _buildSectionHeader('Personal Information', Icons.person_outline),
            const SizedBox(height: AppSpacing.md),

            PremiumTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter patient\'s full name',
              prefixIcon: const Icon(Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ).animate().fadeIn(duration: AppMotion.standard, delay: 50.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard),
            const SizedBox(height: AppSpacing.md),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PremiumTextField(
                    controller: _ageController,
                    label: 'Age',
                    hint: 'Years',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.cake_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final age = int.tryParse(v);
                      if (age == null || age < 1 || age > 120) return 'Invalid age';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gender', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: AppSpacing.xs),
                      ComboBox<String>(
                        items: const ['male', 'female', 'other'],
                        itemAsString: (item) => item.substring(0, 1).toUpperCase() + item.substring(1),
                        hint: 'Male',
                        onChanged: (val) {
                          if (val != null) setState(() => _gender = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(duration: AppMotion.standard, delay: 100.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard),
            const SizedBox(height: AppSpacing.md),

            PremiumTextField(
              controller: _occupationController,
              label: 'Occupation',
              hint: 'e.g., Farmer, Teacher',
              prefixIcon: const Icon(Icons.work_outline),
            ).animate().fadeIn(duration: AppMotion.standard, delay: 150.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader('Physical Measurements', Icons.monitor_weight_outlined),
            const SizedBox(height: AppSpacing.md),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PremiumTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    hint: 'e.g., 65',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null; // optional
                      final w = double.tryParse(v);
                      if (w == null || w <= 0 || w > 300) return 'Invalid weight';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PremiumTextField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    hint: 'e.g., 165',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.height_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null; // optional
                      final h = double.tryParse(v);
                      if (h == null || h <= 0 || h > 300) return 'Invalid height';
                      return null;
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(duration: AppMotion.standard, delay: 175.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader('Contact & Location', Icons.location_on_outlined),
            const SizedBox(height: AppSpacing.md),

            PremiumTextField(
              controller: _contactController,
              label: 'Phone Number',
              hint: '10-digit mobile number',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ).animate().fadeIn(duration: AppMotion.standard, delay: 200.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard),
            const SizedBox(height: AppSpacing.md),

            PremiumTextField(
              controller: _villageController,
              label: 'Village',
              hint: 'Village or town name',
              prefixIcon: const Icon(Icons.location_city_outlined),
            ).animate().fadeIn(duration: AppMotion.standard, delay: 250.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard),
            const SizedBox(height: AppSpacing.md),

            PremiumTextField(
              controller: _addressController,
              label: 'Full Address',
              hint: 'Block, district, state',
              keyboardType: TextInputType.streetAddress,
              prefixIcon: const Icon(Icons.home_outlined),
            ).animate().fadeIn(duration: AppMotion.standard, delay: 300.ms).slideY(begin: 0.1, end: 0, duration: AppMotion.standard),

            const SizedBox(height: AppSpacing.xxl),

            MagneticButton(
              text: 'Add Patient',
              onPressed: patientProvider.isLoading ? () {} : _savePatient,
              isLoading: patientProvider.isLoading,
            ).animate().fadeIn(duration: AppMotion.standard, delay: 400.ms),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: AppTypography.semiBold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/premium/buttons/premium_buttons.dart';
import '../../services/medical_image_service.dart';
import 'package:provider/provider.dart';
import '../../providers/screening_provider.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final List<String> _selectedImages = [];
  final List<ScanAnalysisResult?> _analysisResults = [];
  final ImagePicker _picker = ImagePicker();
  final MedicalImageService _imageService = MedicalImageService();
  bool _isAnalyzing = false;

  int get _bestKLGrade => _analysisResults
      .whereType<ScanAnalysisResult>()
      .map((r) => r.suggestedKLGrade)
      .fold(0, (a, b) => a > b ? a : b);

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImages.add(image.path);
          _analysisResults.add(null);
          _isAnalyzing = true;
        });

        final idx = _selectedImages.length - 1;
        final result = await _imageService.analyzeImage(
          imagePath: image.path,
          jointType: 'knee',
        );

        if (mounted) {
          setState(() {
            _analysisResults[idx] = result;
            _isAnalyzing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _analysisResults.removeAt(index);
    });
  }

  void _proceed() {
    HapticFeedback.mediumImpact();
    
    // Save the highest KL grade found in the images to the provider
    int maxKlGrade = 0;
    for (final result in _analysisResults) {
      if (result != null && result.suggestedKLGrade != null) {
        if (result.suggestedKLGrade > maxKlGrade) {
          maxKlGrade = result.suggestedKLGrade;
        }
      }
    }
    
    final provider = context.read<ScreeningProvider>();
    provider.draftMriKlGrade = maxKlGrade;
    
    context.push('/screening/overview');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'medical_images'.tr(),
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'upload_scans_reports'.tr(),
                      style: AppTypography.headlineMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'attach_available_mris'.tr(),
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Scan-type info banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.biotech_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Supports X-Ray, MRI, CT & USG scans — auto-detected',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Upload area
                    GestureDetector(
                      onTap: _isAnalyzing ? null : _pickImage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: _isAnalyzing
                              ? AppColors.surfaceVariant
                                  .withValues(alpha: 0.5)
                              : AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(
                            color: _isAnalyzing
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.border,
                            width: _isAnalyzing ? 2 : 1,
                          ),
                        ),
                        child: _isAnalyzing
                            ? Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Analyzing scan...',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 48,
                                      color: AppColors.primary),
                                  const SizedBox(height: AppSpacing.md),
                                  Text('tap_to_upload_images'.tr(),
                                      style: AppTypography.bodyMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    'X-Ray  •  MRI  •  CT Scan  •  Ultrasound',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Image cards with analysis
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text('selected_images'.tr(),
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      ...List.generate(_selectedImages.length, (i) {
                        final result = i < _analysisResults.length
                            ? _analysisResults[i]
                            : null;
                        return _ScanCard(
                          imagePath: _selectedImages[i],
                          analysisResult: result,
                          onRemove: () => _removeImage(i),
                        );
                      }),

                      if (_analysisResults.any((r) => r != null)) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _KLGradeSummaryCard(klGrade: _bestKLGrade),
                      ],
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: MagneticButton(
                text: 'next'.tr(),
                onPressed: _proceed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan card ────────────────────────────────────────────────────────────────

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.imagePath,
    required this.analysisResult,
    required this.onRemove,
  });

  final String imagePath;
  final ScanAnalysisResult? analysisResult;
  final VoidCallback onRemove;

  Color _modalityColor(ScanModality m) {
    switch (m) {
      case ScanModality.xray:
        return const Color(0xFF2196F3);
      case ScanModality.mri:
        return const Color(0xFF9C27B0);
      case ScanModality.ct:
        return const Color(0xFF009688);
      case ScanModality.usg:
        return const Color(0xFFE91E63); // Pinkish-red for Ultrasound
      case ScanModality.unknown:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _modalityIcon(ScanModality m) {
    switch (m) {
      case ScanModality.xray:
        return Icons.wb_sunny_outlined;
      case ScanModality.mri:
        return Icons.psychology_outlined;
      case ScanModality.ct:
        return Icons.circle_outlined;
      case ScanModality.usg:
        return Icons.waves_outlined; // Waves for sound/ultrasound
      case ScanModality.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = analysisResult;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusMd)),
                child: Image.file(
                  File(imagePath),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 48, color: AppColors.textSecondary),
                  ),
                ),
              ),
              // Remove
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
              // Modality chip
              if (result != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _modalityColor(result.modality)
                          .withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_modalityIcon(result.modality),
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          result.modalityLabel,
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${(result.modalityConfidence * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color:
                                  Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (result == null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusMd)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    ),
                  ),
                ),
            ],
          ),
          if (result != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _InfoPill(
                        label: 'KL Grade',
                        value: result.biomarkers.estimatedKLGrade
                            .toString(),
                        color: result.biomarkers.estimatedKLGrade >= 3
                            ? Colors.red
                            : result.biomarkers.estimatedKLGrade >= 2
                                ? Colors.orange
                                : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _InfoPill(
                        label: 'Risk',
                        value:
                            '${(result.imageRiskScore * 100).toStringAsFixed(0)}%',
                        color: result.imageRiskScore >= 0.60
                            ? Colors.red
                            : result.imageRiskScore >= 0.35
                                ? Colors.orange
                                : Colors.green,
                      ),
                      if (result.serverValidated) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_done_outlined,
                                  size: 11, color: Colors.green),
                              const SizedBox(width: 4),
                              Text('Server verified',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...result.findings.take(3).map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.primary)),
                            Expanded(
                              child: Text(f,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── KL Grade summary card ─────────────────────────────────────────────────────

class _KLGradeSummaryCard extends StatelessWidget {
  const _KLGradeSummaryCard({required this.klGrade});
  final int klGrade;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.green,
      const Color(0xFF8BC34A),
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
    ];
    final labels = [
      'No OA (Grade 0)',
      'Doubtful OA (Grade 1)',
      'Mild OA (Grade 2)',
      'Moderate OA (Grade 3)',
      'Severe OA (Grade 4)',
    ];
    final color = colors[klGrade.clamp(0, 4)];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                klGrade.toString(),
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggested KL Grade',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
                Text(labels[klGrade.clamp(0, 4)],
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text('Auto-detected from uploaded scans',
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info pill ─────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill(
      {required this.label,
      required this.value,
      required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

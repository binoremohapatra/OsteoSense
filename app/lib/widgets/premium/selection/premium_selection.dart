import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_motion.dart';


/// A premium dropdown that mimics a native popover.
class PremiumDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String Function(T) itemAsString;
  final ValueChanged<T?> onChanged;
  final String hint;

  const PremiumDropdown({
    super.key,
    required this.items,
    this.value,
    required this.itemAsString,
    required this.onChanged,
    this.hint = 'Select...',
  });

  @override
  State<PremiumDropdown<T>> createState() => _PremiumDropdownState<T>();
}

class _PremiumDropdownState<T> extends State<PremiumDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: widget.value,
          hint: Text(widget.hint, style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
          isExpanded: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          items: widget.items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(widget.itemAsString(item)),
            );
          }).toList(),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

/// An animated switch with a premium sliding thumb.
class AnimatedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AnimatedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curveSmooth,
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? AppColors.primary : AppColors.border,
          border: Border.all(
            color: value ? AppColors.primaryDark : AppColors.borderDark.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: AppMotion.fast,
          curve: AppMotion.curveSmooth,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A segmented control for switching between a small number of views.
class SegmentedControl<T> extends StatelessWidget {
  final List<T> segments;
  final T currentSegment;
  final ValueChanged<T> onSegmentChanged;
  final String Function(T) segmentAsString;

  const SegmentedControl({
    super.key,
    required this.segments,
    required this.currentSegment,
    required this.onSegmentChanged,
    required this.segmentAsString,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((segment) {
          final isSelected = segment == currentSegment;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSegmentChanged(segment),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curveSmooth,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    segmentAsString(segment),
                    style: AppTypography.button.copyWith(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A horizontal scrolling or wrapped list of selectable chips.
class ChipSelector<T> extends StatelessWidget {
  final List<T> items;
  final List<T> selectedItems;
  final ValueChanged<T> onToggle;
  final String Function(T) itemAsString;
  final bool isMultiSelect;

  const ChipSelector({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onToggle,
    required this.itemAsString,
    this.isMultiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return GestureDetector(
          onTap: () => onToggle(item),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curveSmooth,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected && isMultiSelect) ...[
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  itemAsString(item),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

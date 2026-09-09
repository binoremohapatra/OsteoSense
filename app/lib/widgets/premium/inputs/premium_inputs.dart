import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_motion.dart';


/// A premium text field with smooth focus animation and clean 1px borders.
class PremiumTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;

  const PremiumTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.errorText,
    this.validator,
    this.inputFormatters,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.caption.copyWith(
              color: _isFocused ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ).animate(target: _isFocused ? 1 : 0).tint(color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
        ],
        AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curveSmooth,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.error
                  : _isFocused
                      ? AppColors.primary
                      : AppColors.border,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused && widget.errorText == null
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: widget.prefixIcon!,
                ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  onChanged: widget.onChanged,
                  validator: widget.validator,
                  inputFormatters: widget.inputFormatters,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              if (widget.suffixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: widget.suffixIcon!,
                ),
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ).animate().fadeIn(duration: AppMotion.fast).slideY(begin: -0.2, end: 0),
        ],
      ],
    );
  }
}

/// A specialized PremiumTextField for searching.
class SearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const SearchField({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTextField(
      hint: hint,
      controller: controller,
      onChanged: onChanged,
      prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
      suffixIcon: controller?.text.isNotEmpty == true
          ? GestureDetector(
              onTap: () {
                controller?.clear();
                if (onChanged != null) onChanged!('');
              },
              child: const Icon(Icons.close, color: AppColors.textTertiary, size: 16),
            )
          : null,
    );
  }
}

/// A field designed for entering OTP codes.
class OTPField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;

  const OTPField({
    super.key,
    this.length = 6,
    this.onCompleted,
  });

  @override
  State<OTPField> createState() => _OTPFieldState();
}

class _OTPFieldState extends State<OTPField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(widget.length, (index) => TextEditingController());
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (widget.onCompleted != null) {
          final code = _controllers.map((c) => c.text).join();
          widget.onCompleted!(code);
        }
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 48,
          child: PremiumTextField(
            controller: _controllers[index],
            keyboardType: TextInputType.number,
            onChanged: (val) => _onChanged(val, index),
          ),
        );
      }),
    );
  }
}

/// A combination of input field and dropdown for selecting from a list of options.
class ComboBox<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemAsString;
  final String hint;
  final ValueChanged<T?>? onChanged;

  const ComboBox({
    super.key,
    required this.items,
    required this.itemAsString,
    this.hint = 'Select an option',
    this.onChanged,
  });

  @override
  State<ComboBox<T>> createState() => _ComboBoxState<T>();
}

class _ComboBoxState<T> extends State<ComboBox<T>> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();
  List<T> _filteredItems = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    // Initialize with the first item selected if items are not empty
    if (widget.items.isNotEmpty) {
      _controller.text = widget.itemAsString(widget.items[0]);
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (_isOpen) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + AppSpacing.xs),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              color: AppColors.surface,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return ListTile(
                      title: Text(
                        widget.itemAsString(item),
                        style: AppTypography.bodyMedium,
                      ),
                      onTap: () {
                        _controller.text = widget.itemAsString(item);
                        if (widget.onChanged != null) widget.onChanged!(item);
                        _focusNode.unfocus();
                      },
                    );
                  },
                ),
              ),
            ).animate().fadeIn(duration: AppMotion.fast).slideY(begin: -0.05, end: 0),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.itemAsString(item).toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
    if (_isOpen) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (!_isOpen) {
            _showOverlay();
          } else {
            _hideOverlay();
          }
        },
        child: PremiumTextField(
          controller: _controller,
          hint: widget.hint,
          suffixIcon: AnimatedRotation(
            turns: _isOpen ? 0.5 : 0.0,
            duration: AppMotion.fast,
            child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
          ),
          onChanged: _filterItems,
        ),
      ),
    );
  }
}

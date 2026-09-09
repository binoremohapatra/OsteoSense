import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class NavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const NavItem({required this.icon, this.selectedIcon, required this.label});
}

/// A premium glassmorphic bottom navigation bar.
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  })  : assert(items.length > 1),
        assert(currentIndex >= 0 && currentIndex < items.length);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppMotion.fast;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingSm,
          AppSpacing.xs,
          AppSpacing.screenPaddingSm,
          AppSpacing.sm,
        ),
        // Keep shadows outside the blur's clip so the bar floats visibly.
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              const BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: AppSpacing.radiusMd,
                offset: Offset(0, AppSpacing.radiusXs),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: AppSpacing.lg,
                offset: const Offset(0, AppSpacing.radiusMd),
                spreadRadius: -AppSpacing.radiusXs,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: AppSpacing.md,
                sigmaY: AppSpacing.md,
              ),
              child: Container(
                height: AppSpacing.xxxl + AppSpacing.xs,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                      .withValues(alpha: 0.88),
                  borderRadius: radius,
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.glassBorder,
                    width: 1.2,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / items.length;
                    final visualIndex =
                        Directionality.of(context) == TextDirection.rtl
                            ? items.length - 1 - currentIndex
                            : currentIndex;
                    // Labels are optional at large accessibility text sizes;
                    // the full name remains available through semantics/tooltips.
                    final showLabels = MediaQuery.textScalerOf(context).scale(
                            Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .fontSize!) <=
                        AppSpacing.sm;

                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: duration,
                          curve: AppMotion.curve,
                          left: itemWidth * visualIndex + AppSpacing.radiusXs,
                          width: itemWidth - AppSpacing.xs,
                          top: AppSpacing.xs,
                          bottom: AppSpacing.xs,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: radius,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: AppSpacing.radiusMd,
                                  offset: const Offset(0, AppSpacing.radiusXs),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(items.length, (index) {
                            return Expanded(
                              child: _GlassNavDestination(
                                item: items[index],
                                selected: currentIndex == index,
                                showLabel: showLabels,
                                duration: duration,
                                onTap: () {
                                  if (index == currentIndex) return;
                                  HapticFeedback.selectionClick();
                                  onTap(index);
                                },
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavDestination extends StatefulWidget {
  final NavItem item;
  final bool selected;
  final bool showLabel;
  final Duration duration;
  final VoidCallback onTap;

  const _GlassNavDestination({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.duration,
    required this.onTap,
  });

  @override
  State<_GlassNavDestination> createState() => _GlassNavDestinationState();
}

class _GlassNavDestinationState extends State<_GlassNavDestination> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.item.label,
      button: true,
      selected: widget.selected,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: Tooltip(
          message: widget.item.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: _focused
                    ? Border.all(
                        color: AppColors.primary, width: AppSpacing.elevationMd)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: widget.selected ? 1.15 : 1,
                    duration: widget.duration,
                    curve: AppMotion.curveSpring,
                    child: Icon(
                      widget.selected
                          ? widget.item.selectedIcon ?? widget.item.icon
                          : widget.item.icon,
                      color: widget.selected
                          ? AppColors.surface
                          : AppColors.textTertiary,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(height: AppSpacing.radiusXs),
                    Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: widget.selected
                                ? AppColors.surface
                                : AppColors.textSecondary,
                            fontWeight: widget.selected
                                ? AppTypography.semiBold
                                : AppTypography.medium,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Crossfades persistent tab layers without remounting their state.
/// A keyed IndexedStack inside AnimatedSwitcher recreates every tab on a
/// switch, resetting forms and restarting data loads. Keep stable layers
/// instead, and hide inactive content from painting, focus, and semantics.
class RetainedTabSwitcher extends StatelessWidget {
  final int currentIndex;
  final List<Widget> children;

  const RetainedTabSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
  }) : assert(currentIndex >= 0 && currentIndex < children.length);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(children.length, (index) {
        return _ShellTab(
          active: index == currentIndex,
          child: children[index],
        );
      }),
    );
  }
}

/// Retains the child just as IndexedStack does, without painting or exposing
/// inactive screens after the outgoing fade has completed.
class _ShellTab extends StatefulWidget {
  final bool active;
  final Widget child;

  const _ShellTab({required this.active, required this.child});

  @override
  State<_ShellTab> createState() => _ShellTabState();
}

class _ShellTabState extends State<_ShellTab> {
  late bool _visible = widget.active;

  @override
  void didUpdateWidget(covariant _ShellTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) _visible = true;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Offstage(
      offstage: reduceMotion ? !widget.active : !_visible,
      child: IgnorePointer(
        ignoring: !widget.active,
        child: ExcludeFocus(
          excluding: !widget.active,
          child: ExcludeSemantics(
            excluding: !widget.active,
            child: AnimatedOpacity(
              opacity: widget.active ? 1 : 0,
              // AppMotion.fast is 300ms; the existing spacing token provides
              // the required 150ms crossfade without changing global motion.
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: AppSpacing.durationFast),
              curve: AppMotion.curve,
              onEnd: () {
                if (!widget.active && _visible) {
                  setState(() => _visible = false);
                }
              },
              child: TickerMode(
                enabled: widget.active,
                child: HeroMode(
                  enabled: widget.active,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An animated tab bar intended for use within pages (not as bottom nav).
class AnimatedTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Stack(
        children: [
          // The animated sliding background for the selected tab
          AnimatedPositioned(
            duration: AppMotion.fast,
            curve: AppMotion.curveSmooth,
            top: 0,
            bottom: 0,
            left: (MediaQuery.of(context).size.width - 2 * AppSpacing.md - 8) / tabs.length * currentIndex,
            width: (MediaQuery.of(context).size.width - 2 * AppSpacing.md - 8) / tabs.length,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          // The text labels
          Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: AppMotion.fast,
                      curve: AppMotion.curveSmooth,
                      style: AppTypography.button.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      child: Text(tabs[index]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// A floating navigation element that can be expanded (like an expandable FAB).
class FloatingNav extends StatefulWidget {
  final IconData mainIcon;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  const FloatingNav({
    super.key,
    this.mainIcon = Icons.add,
    required this.items,
    required this.onTap,
  });

  @override
  State<FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<FloatingNav> with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen)
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(item.label, style: AppTypography.caption),
                  ).animate().fadeIn(duration: AppMotion.fast).slideX(begin: 0.2, end: 0),
                  const SizedBox(width: AppSpacing.sm),
                  FloatingActionButton.small(
                    heroTag: 'fab_$index',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    onPressed: () {
                      _toggle();
                      widget.onTap(index);
                    },
                    child: Icon(item.icon),
                  ).animate().scale(duration: AppMotion.fast),
                ],
              ),
            );
          }).reversed,
        FloatingActionButton(
          heroTag: 'fab_main',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0, // Rotate to make an 'X' if mainIcon is '+'
            duration: AppMotion.fast,
            child: Icon(widget.mainIcon),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CENTERED FAB BOTTOM NAV
// A floating pill-shaped nav bar with 4 items split around a center FAB.
// Replaces GlassBottomNav in the main app shell for the JointSaathi redesign.
// ═══════════════════════════════════════════════════════════════════════════

/// Describes one of the four nav destinations flanking the center FAB.
class CenteredNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const CenteredNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// A floating, pill-shaped bottom navigation bar with a prominent center FAB.
///
/// Layout (LTR):
///   [item0] [item1]   [FAB]   [item2] [item3]
///
/// The [currentIndex] tracks only the 4 nav items (0–3).
/// Tapping the FAB calls [onFabTap]; tapping a destination calls [onTap].
class CenteredFabBottomNav extends StatefulWidget {
  final int currentIndex;
  final List<CenteredNavItem> items;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final IconData fabIcon;

  const CenteredFabBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.onFabTap,
    this.fabIcon = Icons.add_rounded,
  }) : assert(items.length == 4, 'CenteredFabBottomNav requires exactly 4 items');

  @override
  State<CenteredFabBottomNav> createState() => _CenteredFabBottomNavState();
}

class _CenteredFabBottomNavState extends State<CenteredFabBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScale;
  late Animation<double> _fabRotation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    _fabRotation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Left 2 items use indices 0 & 1; right 2 items use indices 2 & 3.
    final leftItems = widget.items.sublist(0, 2);
    final rightItems = widget.items.sublist(2, 4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.surface).withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.softBorder,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0), // Shift icons slightly down
            child: Row(
              children: [
              // Left items
              ...List.generate(2, (i) {
                final item = leftItems[i];
                final index = i; // 0 or 1
                return Expanded(
                  child: _CenteredNavDestination(
                    item: item,
                    selected: widget.currentIndex == index,
                    reduceMotion: reduceMotion,
                    onTap: () {
                      if (widget.currentIndex == index) return;
                      HapticFeedback.selectionClick();
                      widget.onTap(index);
                    },
                  ),
                );
              }),

              // Center Action Button (embedded in navbar)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    _fabController.forward();
                    HapticFeedback.mediumImpact();
                  },
                  onTapUp: (_) {
                    _fabController.reverse();
                    widget.onFabTap();
                  },
                  onTapCancel: () => _fabController.reverse(),
                  child: AnimatedBuilder(
                    animation: _fabController,
                    builder: (context, child) => Transform.scale(
                      scale: _fabScale.value,
                      child: Transform.rotate(
                        angle: _fabRotation.value * 2 * math.pi,
                        child: child,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.fabIcon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Right items
              ...List.generate(2, (i) {
                final item = rightItems[i];
                final index = i + 2; // 2 or 3
                return Expanded(
                  child: _CenteredNavDestination(
                    item: item,
                    selected: widget.currentIndex == index,
                    reduceMotion: reduceMotion,
                    onTap: () {
                      if (widget.currentIndex == index) return;
                      HapticFeedback.selectionClick();
                      widget.onTap(index);
                    },
                  ),
                );
              }),
            ],
          ),
          ), // closing Padding
        ), // closing SizedBox
      ), // closing SafeArea
    ); // closing DecoratedBox
  }
}

class _CenteredNavDestination extends StatefulWidget {
  final CenteredNavItem item;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _CenteredNavDestination({
    required this.item,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  State<_CenteredNavDestination> createState() =>
      _CenteredNavDestinationState();
}

class _CenteredNavDestinationState extends State<_CenteredNavDestination>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        widget.reduceMotion ? Duration.zero : AppMotion.fast;

    return Semantics(
      label: widget.item.label,
      button: true,
      selected: widget.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (context, child) =>
              Transform.scale(scale: _pressScale.value, child: child),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: widget.selected ? 1.18 : 1.0,
                duration: duration,
                curve: AppMotion.curveSpring,
                child: Icon(
                  widget.selected
                      ? widget.item.selectedIcon
                      : widget.item.icon,
                  size: 30,
                  color: widget.selected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedOpacity(
                opacity: widget.selected ? 1.0 : 0.0,
                duration: duration,
                child: AnimatedSlide(
                  offset: widget.selected
                      ? Offset.zero
                      : const Offset(0, 0.4),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppTypography.semiBold,
                      fontSize: 10,
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// SENSOR STATUS CHIP
// A small floating pill that shows sync/connectivity state with a pulsing dot.
// ═══════════════════════════════════════════════════════════════════════════

enum SensorStatus { ready, syncing, offline }

class SensorStatusChip extends StatefulWidget {
  final SensorStatus status;
  final String? customLabel;

  const SensorStatusChip({
    super.key,
    this.status = SensorStatus.ready,
    this.customLabel,
  });

  @override
  State<SensorStatusChip> createState() => _SensorStatusChipState();
}

class _SensorStatusChipState extends State<SensorStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _dotColor {
    switch (widget.status) {
      case SensorStatus.ready:
        return AppColors.riskLow;
      case SensorStatus.syncing:
        return AppColors.warning;
      case SensorStatus.offline:
        return AppColors.textTertiary;
    }
  }

  String get _label {
    if (widget.customLabel != null) return widget.customLabel!;
    switch (widget.status) {
      case SensorStatus.ready:
        return 'Sensor Ready';
      case SensorStatus.syncing:
        return 'Syncing…';
      case SensorStatus.offline:
        return 'Offline';
    }
  }

  bool get _shouldPulse =>
      widget.status == SensorStatus.ready ||
      widget.status == SensorStatus.syncing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Opacity(
                  opacity: _shouldPulse ? _pulse.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _dotColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: AppTypography.medium,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

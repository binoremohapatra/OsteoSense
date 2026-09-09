import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../flutter_flow/flutter_flow_util.dart';

// ============================================================================
// FFButton — production version of FlutterFlow ButtonWidget
//
// variant: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive'
// size:    'small' | 'medium' | 'large'
// ============================================================================

class FFButton extends StatelessWidget {
  const FFButton({
    super.key,
    this.content = 'Get Started',
    this.variant = 'primary',
    this.size = 'large',
    this.fullWidth = true,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.iconEnd,
    this.onTap,
  });

  final String content;
  final String variant;
  final String size;
  final bool fullWidth;
  final bool loading;
  final bool disabled;
  final Widget? icon;
  final Widget? iconEnd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);

    // Colors
    final bg = _bg(ff);
    final fg = _fg(ff);
    final border = _border(ff);
    final radius = _radius();
    final vPad = _vPad();
    final hPad = _hPad();

    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: disabled || loading ? null : onTap,
        child: Container(
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: border,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: loading
                ? Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 8)],
                      Flexible(
                        child: Text(
                          content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: _fontSize(),
                            fontWeight: FontWeight.w600,
                            color: fg,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (iconEnd != null) ...[const SizedBox(width: 8), iconEnd!],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Color _bg(FlutterFlowTheme ff) {
    switch (variant) {
      case 'secondary':
        return ff.secondary;
      case 'outline':
      case 'ghost':
        return Colors.transparent;
      case 'destructive':
        return ff.error;
      default:
        return ff.primary;
    }
  }

  Color _fg(FlutterFlowTheme ff) {
    switch (variant) {
      case 'secondary':
        return ff.onSecondary;
      case 'outline':
        return ff.primaryText;
      case 'ghost':
        return ff.primary;
      case 'destructive':
        return Colors.white;
      default:
        return ff.onPrimary;
    }
  }

  Border? _border(FlutterFlowTheme ff) {
    if (variant == 'outline') {
      return Border.all(color: ff.alternate, width: 1);
    }
    return null;
  }

  double _radius() {
    switch (size) {
      case 'small':
        return 12;
      case 'large':
        return 24;
      default:
        return 16;
    }
  }

  double _vPad() {
    switch (size) {
      case 'small':
        return 8;
      case 'large':
        return 16;
      default:
        return 12;
    }
  }

  double _hPad() {
    switch (size) {
      case 'small':
        return 16;
      case 'large':
        return 32;
      default:
        return 24;
    }
  }

  double _fontSize() {
    switch (size) {
      case 'small':
        return 12;
      case 'large':
        return 14;
      default:
        return 13;
    }
  }
}

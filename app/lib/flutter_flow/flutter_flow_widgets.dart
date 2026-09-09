import 'package:flutter/material.dart';
import 'flutter_flow_util.dart';

class FlutterFlowIconButton extends StatelessWidget {
  const FlutterFlowIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.borderRadius = 8,
    this.buttonSize = 40,
    this.fillColor,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final double borderRadius;
  final double buttonSize;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          alignment: Alignment.center,
          child: icon,
        ),
      ),
    );
  }
}

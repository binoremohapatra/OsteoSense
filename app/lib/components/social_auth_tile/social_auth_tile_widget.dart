import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../flutter_flow/flutter_flow_util.dart';

class SocialAuthTileWidget extends StatefulWidget {
  const SocialAuthTileWidget({
    super.key,
    String? icon,
    String? label,
  })  : this.icon = icon ?? 'https://cdn.simpleicons.org/google/2d2926.svg',
        this.label = label ?? 'Google';

  final String icon;
  final String label;

  @override
  State<SocialAuthTileWidget> createState() => _SocialAuthTileWidgetState();
}

class _SocialAuthTileWidgetState extends State<SocialAuthTileWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.alternate,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.network(
              widget.icon,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: theme.labelLarge.copyWith(
                color: theme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../flutter_flow/flutter_flow_util.dart';

class SyncIndicatorWidget extends StatefulWidget {
  const SyncIndicatorWidget({
    super.key,
    this.status = 'syncing',
  });

  final String status;

  @override
  State<SyncIndicatorWidget> createState() => _SyncIndicatorWidgetState();
}

class _SyncIndicatorWidgetState extends State<SyncIndicatorWidget> {
  @override
  Widget build(BuildContext context) {
    final isSynced = widget.status == 'synced';
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isSynced
            ? theme.primary.withOpacity(0.15)
            : theme.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSynced ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
              size: 14,
              color: isSynced
                  ? theme.primary
                  : theme.error,
            ),
            const SizedBox(width: 4),
            Text(
              isSynced ? 'Synced' : 'Syncing',
              style: theme.labelSmall.copyWith(
                    color: isSynced
                        ? theme.primary
                        : theme.error,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

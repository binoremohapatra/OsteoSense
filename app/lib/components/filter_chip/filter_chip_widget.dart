import 'package:flutter/material.dart';
import '../../flutter_flow/flutter_flow_util.dart';

class FilterChipWidget extends StatefulWidget {
  const FilterChipWidget({
    super.key,
    String? label,
    bool? selected,
  })  : this.label = label ?? 'All Patients',
        this.selected = selected ?? true;

  final String label;
  final bool selected;

  @override
  State<FilterChipWidget> createState() => _FilterChipWidgetState();
}

class _FilterChipWidgetState extends State<FilterChipWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
      child: Container(
        decoration: BoxDecoration(
          color: widget.selected
              ? theme.primary
              : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: widget.selected
                ? theme.primary
                : theme.alternate,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 16),
          child: Text(
            widget.label,
            style: theme.labelLarge.copyWith(
              color: widget.selected
                  ? theme.onPrimary
                  : theme.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

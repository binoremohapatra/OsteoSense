import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../flutter_flow/flutter_flow_util.dart';

class PatientCardWidget extends StatefulWidget {
  const PatientCardWidget({
    super.key,
    String? age,
    String? gender,
    String? initials,
    String? lastScreening,
    String? name,
    String? patientId,
    bool? isSynced,
    String? riskLevel,
  })  : this.age = age ?? '62',
        this.gender = gender ?? 'Male',
        this.initials = initials ?? 'RK',
        this.lastScreening = lastScreening ?? '2 days ago',
        this.name = name ?? 'Rajesh Kumar',
        this.patientId = patientId ?? 'JS-001',
        this.isSynced = isSynced ?? true,
        this.riskLevel = riskLevel ?? 'high';

  final String age;
  final String gender;
  final String initials;
  final String lastScreening;
  final String name;
  final String patientId;
  final bool isSynced;
  final String riskLevel;

  @override
  State<PatientCardWidget> createState() => _PatientCardWidgetState();
}

class _PatientCardWidgetState extends State<PatientCardWidget> {
  Color get _riskColor {
    switch (widget.riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
      child: InkWell(
        onTap: () {
          context.go('/agent/home');
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: AlignmentDirectional(-1, -1),
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.initials,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: theme.labelMedium.copyWith(
                          color: theme.onSecondaryContainer,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(1, 1),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: widget.isSynced
                              ? theme.success
                              : theme.warning,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: theme.secondaryBackground,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              style: theme.titleMedium.copyWith(
                                color: theme.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            widget.patientId,
                            style: theme.labelSmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.age} yrs • ${widget.gender}',
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lastScreening,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
                    child: Text(
                      '${widget.riskLevel.toUpperCase()} RISK',
                      style: theme.labelSmall.copyWith(
                        color: _riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

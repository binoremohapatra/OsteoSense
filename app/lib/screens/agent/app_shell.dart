import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

// ============================================================================
// AppShell — Shell route wrapper for agent screens
//
// Layout (Stack):
//  1. Main content area (child widget passed from GoRouter ShellRoute)
//  2. Background image with opacity
// ============================================================================

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child, required this.currentIndex});

  final Widget child;
  final int currentIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: ff.primaryBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/images/10_app_shell.gif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          // Main content
          widget.child,
        ],
      ),
    );
  }
}

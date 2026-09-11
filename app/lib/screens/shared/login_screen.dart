import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../widgets/ff/ff_button.dart';

// ============================================================================
// LoginScreen — matches FlutterFlow AuthenticationWidget exactly.
//
// Layout (Stack):
//  1. Mesh gradient background (LinearGradient approximation)
//  2. Scrollable body: Logo → Tab switcher → Form fields → Sign In CTA →
//     Social auth → Offline info card → Privacy footer
//  3. "Server Online" pill (top-right)
// ============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.role = 'agent'});

  final String role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMsg;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      bool success;
      if (_isLogin) {
        success = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        final user = User(
          fullName: _nameCtrl.text.trim(),
          phoneNumber: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          healthCenterId: widget.role == 'agent' ? 'HC-001' : null,
          location: null,
        );
        success = await auth.signup(user);
      }
      if (!mounted) return;
      if (success) {
        // Ensure role is set after successful auth
        await auth.saveUserRole();
        context.go('/agent/home');
      } else {
        setState(() => _errorMsg = auth.errorMessage ?? 'Authentication failed');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: ff.primaryBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: ff.primaryText),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/role');
              }
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          alignment: Alignment.topLeft,
          children: [
            // Animated dotted particle background GIF
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/02_authentication.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient if GIF is not found
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-1, -1),
                          end: const Alignment(1, 1),
                          colors: [
                            const Color(0x33A8B5A0),
                            ff.primaryBackground,
                            const Color(0x4DE8DCC4),
                            ff.primaryBackground,
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Scrollable content
            SafeArea(
              child: SingleChildScrollView(
                primary: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // ── Logo block ────────────────────────────────────
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: ff.secondaryBackground,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.health_and_safety_rounded,
                              color: ff.primary,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'JointSaathi',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: ff.primaryText,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI-Assisted Osteoarthritis Screening',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: ff.secondaryText,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Login / Register tab switcher ─────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: ff.surface60,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  _Tab(
                                    label: 'Login',
                                    active: _isLogin,
                                    onTap: () => setState(() => _isLogin = true),
                                  ),
                                  _Tab(
                                    label: 'Register',
                                    active: !_isLogin,
                                    onTap: () => setState(() => _isLogin = false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Form fields ───────────────────────────────────
                      if (!_isLogin) ...[
                        _OutlinedField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Dr. Your Name',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _OutlinedField(
                        controller: _emailCtrl,
                        label: 'Phone Number',
                        hint: 'Enter 10-digit mobile number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _OutlinedField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        trailing: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: ff.primaryText,
                            size: 22,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),

                      if (_isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ff.primary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Error ─────────────────────────────────────────
                      if (_errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ff.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: ff.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMsg!,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: ff.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Sign In button ────────────────────────────────
                      FFButton(
                        content: _isLogin ? 'Sign In to Dashboard' : 'Create Account',
                        variant: 'primary',
                        size: 'large',
                        fullWidth: true,
                        loading: _loading,
                        icon: Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onTap: _submit,
                      ),
                      const SizedBox(height: 16),

                      // ── OR divider ────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                              child: Divider(color: ff.alternate, height: 1)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: ff.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(color: ff.alternate, height: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Social / Demo auth ────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _SocialTile(
                              icon: Icons.g_mobiledata_rounded,
                              label: 'Google',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SocialTile(
                              icon: Icons.apple_rounded,
                              label: 'Apple',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Offline access card ───────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: ff.secondary10,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: ff.secondary30, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.wifi_off_rounded,
                                  color: ff.onSurface, size: 20),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Offline Access Enabled',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: ff.onSurface,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You can log in with cached credentials when offline.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: ff.onSurface,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Privacy footer ────────────────────────────────
                      Column(
                        children: [
                          Text(
                            'By signing in, you agree to our',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: ff.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                'Privacy Policy',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: ff.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              Text('&',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11, color: ff.secondaryText)),
                              Text(
                                'Terms of Service',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: ff.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // ── Server Online pill (top-right) ────────────────────────────
            Positioned(
              top: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ff.surface80,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: ff.alternate, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ff.success,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Server Online',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ff.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab switcher item ────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? ff.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.white : ff.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Outlined text field ──────────────────────────────────────────────────────

class _OutlinedField extends StatelessWidget {
  const _OutlinedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ff.primaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: ff.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ff.alternate, width: 1),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.dmSans(fontSize: 14, color: ff.primaryText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.dmSans(fontSize: 14, color: ff.secondaryText),
              prefixIcon: Icon(icon, color: ff.primaryText, size: 22),
              suffixIcon: trailing,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Social auth tile ─────────────────────────────────────────────────────────

class _SocialTile extends StatelessWidget {
  const _SocialTile(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ff = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: ff.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ff.alternate, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: ff.primaryText),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ff.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ff/ff_button.dart';
import '../../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  
  bool _loading = false;
  String? _errorMsg;
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter phone number');
      return;
    }
    setState(() {
      _errorMsg = null;
      _otpSent = true;
      _otpCtrl.text = '123456'; // Dummy OTP
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test OTP "123456" auto-filled for testing')),
    );
  }

  Future<void> _submit() async {
    if (_phoneCtrl.text.trim().isEmpty || _newPasswordCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill all fields');
      return;
    }
    
    if (_newPasswordCtrl.text.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters');
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final success = await auth.resetPassword(_phoneCtrl.text.trim(), _newPasswordCtrl.text);
    
    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully! You can now log in.')),
        );
        context.pop();
      } else {
        setState(() => _errorMsg = auth.errorMessage ?? 'Failed to reset password');
      }
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
            onPressed: () => context.pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Forgot Password',
            style: GoogleFonts.dmSans(
              color: ff.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reset your password',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ff.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your registered phone number to reset your password.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: ff.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              _OutlinedField(
                controller: _phoneCtrl,
                label: 'phone_number'.tr(),
                hint: '+91 XXXXX XXXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              if (_otpSent) ...[
                _OutlinedField(
                  controller: _otpCtrl,
                  label: 'OTP',
                  hint: 'Enter 6-digit OTP',
                  icon: Icons.message_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _OutlinedField(
                  controller: _newPasswordCtrl,
                  label: 'New Password',
                  hint: 'Enter new password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
              ],

              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ff.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ff.error.withValues(alpha: 0.3)),
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

              if (!_otpSent)
                FFButton(
                  content: 'Send OTP',
                  variant: 'primary',
                  size: 'large',
                  fullWidth: true,
                  onTap: _sendOtp,
                )
              else
                FFButton(
                  content: 'Reset Password',
                  variant: 'primary',
                  size: 'large',
                  fullWidth: true,
                  loading: _loading,
                  onTap: _submit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedField extends StatelessWidget {
  const _OutlinedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

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
              hintStyle: GoogleFonts.dmSans(fontSize: 14, color: ff.secondaryText),
              prefixIcon: Icon(icon, color: ff.primaryText, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

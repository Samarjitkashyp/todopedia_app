import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_provider.dart';

/// A 2-step password reset flow shown as a modal bottom sheet:
///   Step 1 — enter email/username, receive a one-time code.
///   Step 2 — enter the code + a new password.
class ForgotPasswordSheet extends StatefulWidget {
  final String initialIdentifier;
  const ForgotPasswordSheet({super.key, this.initialIdentifier = ""});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  int _step = 1;
  bool _obscure = true;

  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _identifierController.text = widget.initialIdentifier;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _requestCode() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      _showSnack("Please enter your email or username.", error: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.requestPasswordReset(identifier);
    if (!mounted) return;

    if (ok) {
      setState(() => _step = 2);
      _showSnack("If the account exists, a reset code has been sent.");
    } else {
      _showSnack(auth.errorMessage ?? "Could not send reset code.", error: true);
    }
  }

  bool _isStrongPassword(String p) {
    return p.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(p) &&
        RegExp(r'[a-z]').hasMatch(p) &&
        RegExp(r'\d').hasMatch(p) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(p);
  }

  Future<void> _confirmReset() async {
    final identifier = _identifierController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text;

    if (code.isEmpty) {
      _showSnack("Enter the code sent to your email.", error: true);
      return;
    }
    if (!_isStrongPassword(newPassword)) {
      _showSnack(
        "Password needs 8+ chars incl. upper, lower, digit & special character.",
        error: true,
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.confirmPasswordReset(
      identifier: identifier,
      code: code,
      newPassword: newPassword,
    );
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      _showSnack("Password reset successfully. Please log in.");
    } else {
      _showSnack(auth.errorMessage ?? "Could not reset password.", error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final media = MediaQuery.of(context);
    // Lift the sheet above the keyboard...
    final bottomInset = media.viewInsets.bottom;
    // ...and keep content clear of the system navigation bar / gesture area.
    final safeBottom = media.padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 28 + safeBottom),
        decoration: const BoxDecoration(
          color: AppColors.bgStart,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _step == 1 ? "Reset your password" : "Enter reset code",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _step == 1
                  ? "We'll send a one-time code to your registered email."
                  : "Enter the code you received and choose a new password.",
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            if (_step == 1) ..._buildRequestStep() else ..._buildConfirmStep(),

            const SizedBox(height: 20),

            // Primary action button
            GestureDetector(
              onTap: auth.isLoading
                  ? null
                  : (_step == 1 ? _requestCode : _confirmReset),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _step == 1 ? "Send Code" : "Reset Password",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),

            if (_step == 2) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: auth.isLoading ? null : _requestCode,
                  child: Text(
                    "Didn't get a code? Resend",
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRequestStep() {
    return [
      _fieldLabel("Email or Username"),
      _softField(
        controller: _identifierController,
        hint: "Enter your email or username",
        icon: Icons.person_outline_rounded,
      ),
    ];
  }

  List<Widget> _buildConfirmStep() {
    return [
      _fieldLabel("Reset Code"),
      _softField(
        controller: _codeController,
        hint: "6-digit code",
        icon: Icons.pin_outlined,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 6,
      ),
      const SizedBox(height: 14),
      _fieldLabel("New Password"),
      _softField(
        controller: _passwordController,
        hint: "Enter a new strong password",
        icon: Icons.lock_outline_rounded,
        obscure: _obscure,
        suffix: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    ];
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _softField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Container(
      decoration: AppTheme.softNeumorphicDecoration(borderRadius: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          counterText: "",
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

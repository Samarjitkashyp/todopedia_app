import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_provider.dart';
import '../widgets/forgot_password_sheet.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isSignUp) {
      success = await authProvider.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
    } else {
      // In FastAPI backend, logging in checks username OR email dynamically.
      // So we pass the entered email/username string in the username field.
      success = await authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: AppTheme.pageBackgroundGradient,
        height: double.infinity,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                  const SizedBox(height: 10),
                  
                  // 1. Centered 3D Clipboard Logo/Illustration
                  Center(
                    child: Container(
                      height: 110,
                      width: 110,
                      decoration: AppTheme.softNeumorphicDecoration(borderRadius: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          "assets/images/login_illustration.jpg",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(
                              Icons.playlist_add_check_rounded,
                              size: 54,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. Centered App Name: "TodoPedia" (Optimized size)
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        "TodoPedia",
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- SIGNUP FIELDS: FIRST NAME / LAST NAME ---
                  if (_isSignUp) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                                child: Text(
                                  "First Name",
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                              Container(
                                decoration: AppTheme.softNeumorphicDecoration(borderRadius: 16),
                                child: TextFormField(
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                    hintText: "First Name",
                                    hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 14),
                                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                                child: Text(
                                  "Last Name",
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                              Container(
                                decoration: AppTheme.softNeumorphicDecoration(borderRadius: 16),
                                child: TextFormField(
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                    hintText: "Last Name",
                                    hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 14),
                                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- FIELD 1: EMAIL ADDRESS / USERNAME (Matching Mockup) ---
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      _isSignUp ? "Username" : "Email Address / Username",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    decoration: AppTheme.softNeumorphicDecoration(borderRadius: 16),
                    child: TextFormField(
                      controller: _usernameController,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? "Username/Email is required"
                          : null,
                      decoration: InputDecoration(
                        hintText: _isSignUp ? "Enter your username" : "Enter your email or username",
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary),
                        suffixIcon: const Icon(Icons.contact_mail_outlined, color: AppColors.textSecondary, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textPrimary),
                    ),
                  ),
                  
                  const SizedBox(height: 18),

                  // --- SIGNUP SPECIAL FIELD: EMAIL ---
                  if (_isSignUp) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        "Email Address",
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      decoration: AppTheme.softNeumorphicDecoration(borderRadius: 16),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value == null || !value.contains('@'))
                            ? "Enter a valid email address"
                            : null,
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 14),
                          prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // --- FIELD 2: PASSWORD (Matching Mockup) ---
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      "Password",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    decoration: AppTheme.softNeumorphicDecoration(borderRadius: 16),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) => (value == null || value.length < 6)
                          ? "Password must be at least 6 characters"
                          : null,
                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textPrimary),
                    ),
                  ),

                  // Sign Up Link & Forgot Password Row
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Toggle login/signup state link
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUp ? "Have account? " : "No account? ",
                              ),
                              TextSpan(
                                text: _isSignUp ? "Sign In" : "Sign Up",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Forgot Password Link (Only shown in Login mode)
                      if (!_isSignUp)
                        TextButton(
                          onPressed: () {
                            // Open the secure password-reset flow (email OTP).
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ForgotPasswordSheet(
                                initialIdentifier: _usernameController.text.trim(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- LOGIN BUTTON (Matching Mockup) ---
                  GestureDetector(
                    onTap: authProvider.isLoading ? null : _submit,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isSignUp ? "Sign Up" : "Login",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

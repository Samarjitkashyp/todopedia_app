import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'viewmodels/auth_provider.dart';
import 'viewmodels/todo_provider.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/login_screen.dart';

import 'viewmodels/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TodoPedia',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthCheckScreen(),
          );
        },
      ),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _performAuthCheck();
  }

  void _performAuthCheck() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Verifies if there are existing JWT tokens and attempts to restore session
    final isLoggedIn = await authProvider.checkAuthStatus();
    
    if (mounted) {
      setState(() {
        _isAuthenticated = isLoggedIn;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash load state during initial auth validation
    if (_isChecking) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.pageBackgroundGradient,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.softNeumorphicDecoration(borderRadius: 24),
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "TodoPedia",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}

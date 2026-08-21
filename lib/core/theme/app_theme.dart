import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Theme Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFF8A7EFC);
  
  // Background gradient colors
  static const Color bgStart = Color(0xFFF1F4FA);
  static const Color bgEnd = Color(0xFFE8EBFA);
  
  // Cards and Containers
  static const Color cardBg = Colors.white;
  static const Color shadowLight = Colors.white;
  static const Color shadowDark = Color(0xFFD2D9E8);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF8A9BA8);

  // Quick Stats Icon Colors & Backgrounds
  static const Color allTasksIcon = Color(0xFF4A89FF);
  static const Color allTasksBg = Color(0xFFEEF3FF);

  static const Color completedIcon = Color(0xFF2EC4B6);
  static const Color completedBg = Color(0xFFE6FAF7);

  static const Color pendingIcon = Color(0xFFFF9F1C);
  static const Color pendingBg = Color(0xFFFFF6E6);

  static const Color importantIcon = Color(0xFF9B5DE5);
  static const Color importantBg = Color(0xFFF5ECFF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.outfit(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.outfit(color: AppColors.textSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: GoogleFonts.outfit(color: Colors.white),
        bodyMedium: GoogleFonts.outfit(color: Colors.white70),
      ),
    );
  }

  // Neumorphic decoration style matching the mockup cards
  static BoxDecoration neumorphicDecoration({
    double borderRadius = 20.0,
    Color backgroundColor = AppColors.cardBg,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowLight,
          offset: Offset(-5, -5),
          blurRadius: 10,
        ),
        BoxShadow(
          color: AppColors.shadowDark,
          offset: Offset(5, 5),
          blurRadius: 10,
        ),
      ],
    );
  }

  // Neumorphic decoration for buttons/widgets with inner indentation/lesser intensity
  static BoxDecoration softNeumorphicDecoration({
    double borderRadius = 15.0,
  }) {
    return BoxDecoration(
      color: AppColors.cardBg.withOpacity(0.9),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowLight,
          offset: const Offset(-3, -3),
          blurRadius: 6,
        ),
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.8),
          offset: const Offset(3, 3),
          blurRadius: 6,
        ),
      ],
    );
  }

  // Linear gradient background for pages
  static BoxDecoration get pageBackgroundGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.bgStart,
          Color(0xFFEAEFFE),
          Color(0xFFF5EAFF), // Lavender hues
          AppColors.bgEnd,
        ],
      ),
    );
  }

  // Button primary gradient
  static Gradient get primaryGradient {
    return const LinearGradient(
      colors: [
        Color(0xFF8A7EFC),
        Color(0xFF6C63FF),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

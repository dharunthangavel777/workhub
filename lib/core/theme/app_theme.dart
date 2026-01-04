import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_colors.dart';

class AppTheme {
  static ThemeData darkTheme = lightTheme;

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: CustomColors.primaryBlue,
    scaffoldBackgroundColor: CustomColors.lightBg,
    cardColor: CustomColors.lightCard,
    colorScheme: const ColorScheme.light(
      primary: CustomColors.primaryBlue,
      secondary: CustomColors.darkBlue,
      surface: CustomColors.lightBg,
      error: CustomColors.errorRed,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 30.4,
        fontWeight: FontWeight.bold,
        color: CustomColors.darkText,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22.8,
        fontWeight: FontWeight.w600,
        color: CustomColors.darkText,
      ),
      bodyLarge:
          GoogleFonts.inter(fontSize: 15.2, color: CustomColors.darkText),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13.3,
        color: CustomColors.textMuted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 19.0,
        fontWeight: FontWeight.bold,
        color: CustomColors.darkText,
      ),
      iconTheme: IconThemeData(color: CustomColors.darkText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle:
            GoogleFonts.inter(fontSize: 15.2, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CustomColors.primaryBlue,
          width: 1.5,
        ),
      ),
      hintStyle: const TextStyle(color: CustomColors.textMuted),
    ),
  );
}

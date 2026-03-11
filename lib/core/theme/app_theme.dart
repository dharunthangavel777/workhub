import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_colors.dart';
import '../design_system/tokens.dart';

class EnterpriseThemeExtension
    extends ThemeExtension<EnterpriseThemeExtension> {
  final List<BoxShadow> cardElevation;
  final Duration fastAnimation;
  final Duration mediumAnimation;

  EnterpriseThemeExtension({
    required this.cardElevation,
    required this.fastAnimation,
    required this.mediumAnimation,
  });

  @override
  ThemeExtension<EnterpriseThemeExtension> copyWith({
    List<BoxShadow>? cardElevation,
    Duration? fastAnimation,
    Duration? mediumAnimation,
  }) {
    return EnterpriseThemeExtension(
      cardElevation: cardElevation ?? this.cardElevation,
      fastAnimation: fastAnimation ?? this.fastAnimation,
      mediumAnimation: mediumAnimation ?? this.mediumAnimation,
    );
  }

  @override
  ThemeExtension<EnterpriseThemeExtension> lerp(
    ThemeExtension<EnterpriseThemeExtension>? other,
    double t,
  ) {
    if (other is! EnterpriseThemeExtension) return this;
    return EnterpriseThemeExtension(
      cardElevation:
          cardElevation, // Elevation doesn't lerp easily in this simplified model
      fastAnimation: other.fastAnimation,
      mediumAnimation: other.mediumAnimation,
    );
  }
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: CustomColors.primaryBlue,
    scaffoldBackgroundColor: const Color(0xFF0F1115),
    cardColor: const Color(0xFF1A1D23),
    colorScheme: const ColorScheme.dark(
      primary: CustomColors.primaryBlue,
      secondary: CustomColors.darkBlue,
      surface: Color(0xFF1A1D23),
      error: CustomColors.errorRed,
    ),
    extensions: [
      EnterpriseThemeExtension(
        cardElevation: AppTokens.elevationMedium,
        fastAnimation: AppTokens.durationFast,
        mediumAnimation: AppTokens.durationMedium,
      ),
    ],
    textTheme:
        GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.7),
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle:
            GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

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
    extensions: [
      EnterpriseThemeExtension(
        cardElevation: AppTokens.elevationLow,
        fastAnimation: AppTokens.durationFast,
        mediumAnimation: AppTokens.durationMedium,
      ),
    ],
    textTheme:
        GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: CustomColors.darkText,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: CustomColors.darkText,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: CustomColors.darkText,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: CustomColors.textMuted,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CustomColors.textMuted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: CustomColors.darkText,
      ),
      iconTheme: const IconThemeData(color: CustomColors.darkText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle:
            GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
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

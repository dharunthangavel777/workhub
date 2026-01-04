import 'package:flutter/material.dart';

class CustomColors {
  // Primary Palette
  static const Color primaryBlue = Color(0xFF000FE2);
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFFE0F2FE);

  // Backgrounds
  static const Color darkBg = Color(0xFF171717);
  static const Color darkCard = Color(0xFF262626);
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color whiteBg = Color(0xFFFFFFFF);

  // Accents
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Text
  static const Color textMain = Color(0xFFE5E5E5);
  static const Color textMuted = Color(0xFFA3A3A3);
  static const Color darkText = Color(0xFF000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF171717), Color(0xFF262626)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

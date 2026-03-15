import 'package:flutter/material.dart';
import 'custom_colors.dart';

class ThemeHelper {
  // Grays
  Color get gray50 => const Color(0xFFF9FAFB);
  Color get gray100 => const Color(0xFFF3F4F6);
  Color get gray200 => const Color(0xFFE5E7EB);
  Color get gray300 => const Color(0xFFD1D5DB);
  Color get gray400 => const Color(0xFF9CA3AF);
  Color get gray500 => const Color(0xFF6B7280);
  Color get gray600 => const Color(0xFF4B5563);
  Color get gray700 => const Color(0xFF374151);
  Color get gray800 => const Color(0xFF1F2937);
  Color get gray900 => const Color(0xFF111827);
  Color get orange600 => const Color(0xFFEA580C);

  // Indigo / Blues
  Color get indigoA700 => CustomColors.primaryBlue;
  Color get indigo50 => const Color(0xFFE8EAF6);
  Color get deepPurple900 => const Color(0xFF311B92);
  Color get indigoA70001 => const Color(0xFF304FFE);

  // Accents
  Color get color66FFFF => const Color(0x66FFFFFF);
  Color get color3F0000 => const Color(0x3F000000);
  Color get colorFFE0E0 => const Color(0xFFFFE0E0);

  // Standard
  Color get whiteA700 => const Color(0xFFFFFFFF);
  Color get whiteA70001 => const Color(0xFFFFFFFF);
  Color get black900 => const Color(0xFF000000);
}

final appTheme = ThemeHelper();




import 'package:flutter/material.dart';
import 'custom_colors.dart';

class ThemeHelper {
  // Grays
  Color get gray_50 => const Color(0xFFF9FAFB);
  Color get gray_100 => const Color(0xFFF3F4F6);
  Color get gray_400 => const Color(0xFF9CA3AF);
  Color get gray_600 => const Color(0xFF4B5563);

  // Indigo / Blues
  Color get indigo_A700 => CustomColors.primaryBlue;
  Color get indigo_50 => const Color(0xFFE8EAF6);
  Color get deep_purple_900 => const Color(0xFF311B92);
  Color get indigo_A700_01 => const Color(0xFF304FFE);

  // Accents
  Color get color66FFFF => const Color(0x66FFFFFF);
  Color get color3F0000 => const Color(0x3F000000);
  Color get colorFFE0E0 => const Color(0xFFFFE0E0);

  // Standard
  Color get white_A700 => const Color(0xFFFFFFFF);
  Color get white_A700_01 => const Color(0xFFFFFFFF);
  Color get black_900 => const Color(0xFF000000);
}

final appTheme = ThemeHelper();

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTokens {
  // Motion Tokens
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 400);
  static const Duration durationSlow = Duration(milliseconds: 600);

  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveEmphasized = Curves.easeOutQuint;
  static const Curve curveDecelerated = Curves.easeOutCubic;

  // Elevation Tokens
  static List<BoxShadow> elevationNone = [];

  static List<BoxShadow> elevationLow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevationMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> elevationHigh = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  // Haptic Patterns
  static Future<void> hapticSuccess() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> hapticError() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  static Future<void> hapticSelection() async {
    await HapticFeedback.selectionClick();
  }
}




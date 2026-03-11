import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;

  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}

extension ResponsiveExtension on num {
  double get h => toDouble();
  double get w => toDouble();
  double get fSize => toDouble();
}




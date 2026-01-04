import 'package:flutter/material.dart';

extension ResponsiveExtension on num {
  double get h => this
      .toDouble(); // For now, return as is, or we can add basic scaling logic
  double get w => this.toDouble();
  double get fSize => this.toDouble();
}

extension SizeUtils on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;
}

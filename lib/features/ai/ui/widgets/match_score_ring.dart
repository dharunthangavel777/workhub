import 'package:flutter/material.dart';
import 'package:work_hub/core/theme/theme_helper.dart';
import 'package:work_hub/core/theme/text_style_helper.dart';

class MatchScoreRing extends StatelessWidget {
  final double score; // 0.0 to 100.0
  final double size;
  final double strokeWidth;

  const MatchScoreRing({
    super.key,
    required this.score,
    this.size = 60,
    this.strokeWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on score
    Color ringColor;
    if (score >= 85) {
      ringColor = Colors.greenAccent;
    } else if (score >= 60) {
      ringColor = Colors.amberAccent;
    } else {
      ringColor = Colors.redAccent;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: strokeWidth,
            backgroundColor: appTheme.gray_200,
            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
          ),
          Center(
            child: Text(
              '${score.toInt()}%',
              style: TextStyleHelper.instance.body12Bold.copyWith(
                color: appTheme.gray_900,
                fontSize: size * 0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





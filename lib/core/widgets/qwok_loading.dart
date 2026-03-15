import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:qwok/core/theme/custom_colors.dart';

class QwokLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const QwokLoading({
    super.key,
    this.size = 50.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitDoubleBounce(
        color: color ?? CustomColors.primaryBlue,
        size: size,
      ),
    );
  }
}

class QwokLoadingOverlay extends StatelessWidget {
  final String? message;

  const QwokLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const QwokLoading(color: Colors.white),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

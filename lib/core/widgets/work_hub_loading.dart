import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:work_hub/core/theme/custom_colors.dart';

class WorkHubLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const WorkHubLoading({
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

class WorkHubLoadingOverlay extends StatelessWidget {
  final String? message;

  const WorkHubLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WorkHubLoading(color: Colors.white),
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

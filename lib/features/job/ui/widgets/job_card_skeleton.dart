import 'package:flutter/material.dart';
import 'package:qwok/core/shared_widgets/predictive_shimmer.dart';

class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Placeholder - Rounded Square as per image
              PredictiveShimmer(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    PredictiveShimmer(width: 140, height: 16),
                    SizedBox(height: 10),
                    // Subtitle placeholder
                    PredictiveShimmer(width: 200, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Description line 1 - full
          PredictiveShimmer(width: double.infinity, height: 10),
          SizedBox(height: 12),
          // Description line 2 - nearly full
          PredictiveShimmer(width: double.infinity, height: 10),
          SizedBox(height: 12),
          // Description line 3 - partial
          PredictiveShimmer(width: 180, height: 10),
        ],
      ),
    );
  }
}

class StatsSkeleton extends StatelessWidget {
  const StatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          3,
          (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      PredictiveShimmer(width: 30, height: 20),
                      SizedBox(height: 8),
                      PredictiveShimmer(width: 50, height: 12),
                    ],
                  ),
                ),
              )),
    );
  }
}




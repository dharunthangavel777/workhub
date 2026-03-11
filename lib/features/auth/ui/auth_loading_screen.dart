import 'package:flutter/material.dart';
import 'package:work_hub/core/theme/custom_colors.dart';
import 'package:work_hub/core/shared_widgets/predictive_shimmer.dart';
import 'package:work_hub/core/shared_widgets/universal_skeleton.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Blue Header section matching AnimatedProfileHeaderDelegate roughly
            Container(
              color: CustomColors.primaryBlue,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
                      .copyWith(top: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Profile image skeleton
                          PredictiveShimmer(
                            width: 50,
                            height: 50,
                            borderRadius: BorderRadius.circular(25),
                            baseColor: Colors.white.withValues(alpha: 0.2),
                            highlightColor: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Welcome,",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 6),
                              PredictiveShimmer(
                                width: 100,
                                height: 16,
                                baseColor: Colors.white.withValues(alpha: 0.2),
                                highlightColor:
                                    Colors.white.withValues(alpha: 0.4),
                              ),
                            ],
                          )
                        ],
                      ),
                      // Notifications/Messenger and toggle switch skeleton
                      Row(
                        children: [
                          PredictiveShimmer(
                            width: 60,
                            height: 30,
                            borderRadius: BorderRadius.circular(15),
                            baseColor: Colors.white.withValues(alpha: 0.2),
                            highlightColor: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 12),
                          PredictiveShimmer(
                            width: 40,
                            height: 40,
                            borderRadius: BorderRadius.circular(20),
                            baseColor: Colors.white.withValues(alpha: 0.2),
                            highlightColor: Colors.white.withValues(alpha: 0.4),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search bar skeleton
                  Row(
                    children: [
                      Expanded(
                        child: PredictiveShimmer(
                          width: double.infinity,
                          height: 50,
                          borderRadius: BorderRadius.circular(25),
                          baseColor: Colors.white.withValues(alpha: 0.2),
                          highlightColor: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PredictiveShimmer(
                        width: 50,
                        height: 50,
                        borderRadius: BorderRadius.circular(25),
                        baseColor: Colors.white.withValues(alpha: 0.2),
                        highlightColor: Colors.white.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content below
            Expanded(
              child: Container(
                color: CustomColors.lightBg,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Recently Posted" text skeleton
                      const SizedBox(height: 16),
                      const PredictiveShimmer(
                        width: 140,
                        height: 20,
                      ),
                      const SizedBox(height: 16),
                      // Job card skeletons
                      UniversalSkeleton.card(),
                      UniversalSkeleton.card(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

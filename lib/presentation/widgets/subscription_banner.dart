import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:work_hub/theme/custom_colors.dart';

class SubscriptionBanner extends StatelessWidget {
  final String tier;

  const SubscriptionBanner({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final isPro = tier == 'Pro' || tier == 'Enterprise';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPro
              ? [CustomColors.primaryBlue, Colors.purple]
              : [
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isPro ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPro
                  ? Colors.white.withValues(alpha: 0.1)
                  : CustomColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPro ? FontAwesomeIcons.crown : FontAwesomeIcons.rocket,
              color: isPro ? Colors.white : CustomColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? "Premium Member" : "Upgrade to Pro",
                  style: TextStyle(
                    color: isPro ? Colors.white : CustomColors.darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isPro
                      ? "You are using the $tier plan"
                      : "Unlock unlimited applicants and badges",
                  style: TextStyle(
                    color: isPro
                        ? Colors.white.withValues(alpha: 0.7)
                        : CustomColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isPro)
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                "Upgrade",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

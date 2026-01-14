import 'package:flutter/material.dart';
import '../../core/theme/custom_colors.dart';
import '../../core/theme/text_style_helper.dart';

class BecomeHirerBanner extends StatelessWidget {
  const BecomeHirerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            CustomColors.primaryBlue,
            Color(0xFF4C5DF4), // A slightly lighter blue for gradient
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CustomColors.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Become a Hirer",
                  style: TextStyleHelper.instance.title20SemiBold.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Find top talent for your projects today.",
                  style: TextStyleHelper.instance.body14Medium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigation to hirer form
              Navigator.pushNamed(context, '/become_hirer');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: CustomColors.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              "Hire Now !",
              style: TextStyleHelper.instance.body14Bold.copyWith(
                color: CustomColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qwok/core/theme/theme_helper.dart';
import 'package:qwok/core/theme/text_style_helper.dart';
import 'match_score_ring.dart';

class AIMatchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double matchScore;
  final List<String> reasons;
  final VoidCallback? onTap;

  const AIMatchCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.matchScore,
    this.reasons = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appTheme.whiteA700,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border:
              Border.all(color: appTheme.indigoA700.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            // Score Ring
            MatchScoreRing(score: matchScore),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleHelper.instance.body16Bold.copyWith(
                      color: appTheme.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyleHelper.instance.body14Regular.copyWith(
                      color: appTheme.gray600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: reasons
                          .take(2)
                          .map((reason) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: appTheme.indigo50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  reason,
                                  style: TextStyleHelper.instance.body10Medium
                                      .copyWith(
                                    color: appTheme.indigoA700,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}





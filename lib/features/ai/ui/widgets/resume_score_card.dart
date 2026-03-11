import 'package:flutter/material.dart';
import '../../domain/models/resume_score_model.dart';

class ResumeScoreCard extends StatelessWidget {
  final ResumeScore score;

  const ResumeScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    Color scoreColor = _getScoreColor(score.score);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: score.score / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Text(
                    '${score.score}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Profile Score',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Based on your skills and experience clarity.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildInsightSection(
            title: 'Strengths',
            items: score.strengths,
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildInsightSection(
            title: 'Suggestions',
            items: score.suggestions,
            icon: Icons.lightbulb_outline,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: Text('• $item', style: const TextStyle(fontSize: 13)),
            )),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}

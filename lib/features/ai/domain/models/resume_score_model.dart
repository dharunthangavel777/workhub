class ResumeScore {
  final int score;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;

  ResumeScore({
    required this.score,
    this.strengths = const [],
    this.weaknesses = const [],
    this.suggestions = const [],
  });

  factory ResumeScore.fromJson(Map<String, dynamic> json) {
    return ResumeScore(
      score: json['score'] ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'suggestions': suggestions,
    };
  }
}




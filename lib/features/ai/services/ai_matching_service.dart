class AIMatchingService {
  // Singleton pattern
  static final AIMatchingService _instance = AIMatchingService._internal();
  factory AIMatchingService() => _instance;
  AIMatchingService._internal();

  /// Local "Hybrid Simple AI" matching logic.
  /// No backend required. Offline capable.
  Future<List<Map<String, dynamic>>> getMatches({
    required Map<String, dynamic> workerProfile,
    required List<Map<String, dynamic>> jobs,
  }) async {
    // Simulate "AI Processing" delay for specific UX feeling
    await Future.delayed(const Duration(milliseconds: 800));

    List<Map<String, dynamic>> scoredJobs = [];

    // Normalize worker data
    final workerSkills = (workerProfile['skills'] as List<dynamic>?)
            ?.map((s) => s.toString().toLowerCase().trim())
            .toList() ??
        [];
    final workerTitle =
        (workerProfile['profile_title'] as String?)?.toLowerCase().trim() ?? '';
    // Bio is unused for simple matching to keep it fast, but could be added later

    for (var job in jobs) {
      double score = 0;
      List<String> matchReasons = [];

      // --- 1. Tag Matching (Skills) [Max 40 points] ---
      final jobSkills = (job['required_skills'] as List<dynamic>?)
              ?.map((s) => s.toString().toLowerCase().trim())
              .toList() ??
          [];

      if (jobSkills.isNotEmpty) {
        int matchCount = 0;
        double verificationBonus = 0;

        for (var rawSkill in (workerProfile['skills'] as List<dynamic>? ?? [])) {
          final String skillName = rawSkill is Map 
              ? (rawSkill['name'] ?? '').toString().toLowerCase().trim()
              : rawSkill.toString().toLowerCase().trim();
          
          final bool isVerified = rawSkill is Map 
              ? (rawSkill['isVerified'] == true)
              : false;

          if (jobSkills.any((js) => js.contains(skillName) || skillName.contains(js))) {
            matchCount++;
            if (isVerified) {
              verificationBonus += 5; // +5 points for each matched verified skill
            }
          }
        }

        if (matchCount > 0) {
          // Formula: (matched / required) * 40
          double skillScore = (matchCount / jobSkills.length) * 40;
          if (skillScore > 40) skillScore = 40; // Cap at 40
          score += (skillScore + verificationBonus);

          String reason = '$matchCount matching skill${matchCount > 1 ? 's' : ''}';
          if (verificationBonus > 0) {
            reason += ' (Verified ✨)';
          }
          matchReasons.add(reason);
        }
      }

      // --- 2. Category Relevance [Max 25 points] ---
      final jobCategory =
          (job['category'] as String?)?.toLowerCase().trim() ?? '';
      if (jobCategory.isNotEmpty && workerTitle.isNotEmpty) {
        if (jobCategory.contains(workerTitle) ||
            workerTitle.contains(jobCategory)) {
          score += 25;
          matchReasons.add('Category match');
        }
      }

      // --- 3. Title Relevance [Max 20 points] ---
      final jobTitle = (job['title'] as String?)?.toLowerCase().trim() ?? '';
      if (jobTitle.isNotEmpty && workerTitle.isNotEmpty) {
        // Bi-directional containment check
        if (jobTitle.contains(workerTitle) || workerTitle.contains(jobTitle)) {
          score += 20;
          // Avoid duplicate reason if category already matched similar text
          if (!matchReasons.contains('Role match') && jobCategory != jobTitle) {
            matchReasons.add('Role match');
          }
        }
      }

      // --- 4. Description Context [Max 15 points] ---
      final jobDesc =
          (job['description'] as String?)?.toLowerCase().trim() ?? '';
      if (jobDesc.isNotEmpty) {
        // Bonus: If job description mentions the worker's exact title
        if (workerTitle.isNotEmpty && jobDesc.contains(workerTitle)) {
          score += 15;
        }
        // fallback: checking skills in description if not already matched in tags
        else if (workerSkills.any((s) => jobDesc.contains(s))) {
          score += 10;
        }
      }

      // --- Add Matches ---
      // LOWERED THRESHOLD: Show jobs with score > 5 to avoid empty states
      if (score > 5) {
        scoredJobs.add({
          ...job,
          'match_score': score,
          'match_reasons': matchReasons,
        });
      }
    }

    // Sort by Score Descending (Best Match First)
    scoredJobs.sort(
        (a, b) => (b['match_score'] as num).compareTo(a['match_score'] as num));

    return scoredJobs;
  }
}




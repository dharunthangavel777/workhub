import '../domain/models/job.dart';

class JobFilterHelper {
  /// Pure function for filtering jobs/projects.
  /// Used by background isolates to keep the UI at 144 FPS.
  static List<Job> filterJobsTask(Map<String, dynamic> params) {
    final List<Job> posts = params['posts'] as List<Job>;
    final String query = (params['query'] as String).toLowerCase();
    final Set<String> appliedIds = params['appliedIds'] as Set<String>;

    return posts.where((p) {
      final matchesSearch = query.isEmpty ||
          p.title.toLowerCase().contains(query) ||
          (p.companyName?.toLowerCase().contains(query) ?? false);

      return p.status != 'filled' &&
          p.status != 'closed' &&
          !appliedIds.contains(p.id) &&
          matchesSearch;
    }).toList();
  }
}

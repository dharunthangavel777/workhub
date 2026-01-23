import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/theme_helper.dart';
import '../../../../theme/text_style_helper.dart';
import '../../widgets/ai/ai_match_card.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../data/services/ai_matching_service.dart';
import '../../../data/models/job_post_model.dart';
import '../../../data/models/project_post_model.dart';
import '../shared/job_details_screen.dart';
import '../../../data/services/ai_cache_service.dart';

class AIMatchmakingScreen extends StatefulWidget {
  const AIMatchmakingScreen({super.key});

  @override
  State<AIMatchmakingScreen> createState() => _AIMatchmakingScreenState();
}

class _AIMatchmakingScreenState extends State<AIMatchmakingScreen> {
  bool _isLoading = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _matches = [];
  String? _error;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  Future<void> _checkCache() async {
    setState(() => _isLoading = true);
    final cachedMatches = await AICacheService().getValidMatches();
    if (cachedMatches != null && cachedMatches.isNotEmpty) {
      final remaining = await AICacheService().getTimeRemaining();
      if (mounted) {
        setState(() {
          _matches = cachedMatches;
          _hasSearched = true;
          _isLoading = false;
          _timeRemaining = remaining;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchMatches() async {
    final authProvider = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      setState(() => _error = "Please login to see matches.");
      return;
    }

    // Check if we are still within the lock period (unless forced)
    final remaining = await AICacheService().getTimeRemaining();
    if (remaining.inMinutes > 0 && _matches.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "AI results are cached for 24h. Next refresh in ${remaining.inHours}h ${remaining.inMinutes % 60}m.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      // 1. Prepare Worker Profile
      final workerProfile = {
        'profile_title': user.jobCategory ?? '',
        'bio': user.bio ?? '',
        'skills': user.skills ?? [],
      };

      // 2. Prepare Jobs & Projects
      final List<JobPostModel> allJobs = jobProvider.jobPosts;
      final List<ProjectPostModel> allProjects = jobProvider.projectPosts;

      final candidatesData = [
        ...allJobs.map((job) => {
              'id': job.id,
              'title': job.jobTitle,
              'description': job.jobSummary,
              'required_skills': job.requiredSkills,
              'budget': job.salaryRange,
              'category': job.jobCategory,
              'type': 'job',
            }),
        ...allProjects.map((project) => {
              'id': project.id,
              'title': project.projectTitle,
              'description': project.projectDescription,
              'required_skills': project.requiredSkills,
              'budget': '₹${project.budgetMin} - ₹${project.budgetMax}',
              'category': project.projectCategory,
              'type': 'project',
            }),
      ];

      if (candidatesData.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = "No jobs or projects available to match.";
        });
        return;
      }

      // 3. Call AI Service
      final matches = await AIMatchingService().getMatches(
        workerProfile: workerProfile,
        jobs: candidatesData,
      );

      // 4. Save to Cache
      if (matches.isNotEmpty) {
        await AICacheService().saveMatches(matches);
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
          _timeRemaining = const Duration(hours: 24);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load matches. Is the AI service running?";
          _isLoading = false;
        });
      }
      debugPrint("AI Match Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_50,
      appBar: AppBar(
        title: Text(
          'AI Matchmaking',
          style: TextStyleHelper.instance.title20SemiBold.copyWith(
            color: appTheme.gray_900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_hasSearched)
            // Only show refresh if cache expired or for dev purposes (long press?)
            // For now, let's keep it but logic inside blocks it if cached.
            IconButton(
              icon: Icon(Icons.refresh, color: appTheme.gray_900),
              onPressed: _fetchMatches,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Analyzing your profile against available jobs...",
              style: TextStyleHelper.instance.body14Regular,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: appTheme.orange_600),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyleHelper.instance.body16Regular,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMatches,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.indigo_A700,
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    // Initial State - Before Search
    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: appTheme.indigo_A700.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: appTheme.indigo_A700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Find Your Perfect Match",
                style: TextStyleHelper.instance.headline22Bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Let our AI analyze your profile and find the best job opportunities tailored just for you.",
                style: TextStyleHelper.instance.body16Regular.copyWith(
                  color: appTheme.gray_600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _fetchMatches,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.indigo_A700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    "Start AI Matchmaking",
                    style: TextStyleHelper.instance.body16Regular.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: appTheme.gray_400),
            const SizedBox(height: 16),
            Text(
              "No matches found using AI.\nTry updating your profile skills.",
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.body16Regular,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _fetchMatches,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Hero Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appTheme.indigo_A700,
                        appTheme.indigo_A700.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: appTheme.indigo_A700.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
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
                              'Top AI Picks',
                              style: TextStyleHelper.instance.headline22Bold
                                  .copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_matches.length} jobs matched to your skills.',
                              style: TextStyleHelper.instance.body14Regular
                                  .copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // List Title
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Recommended for You',
              style: TextStyleHelper.instance.title20SemiBold,
            ),
          ),
        ),

        // Matches List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final match = _matches[index];
              return AIMatchCard(
                title: match['title'] ?? 'Unknown Job',
                subtitle: match['description'] ?? '',
                matchScore: (match['match_score'] as num?)?.toDouble() ?? 0.0,
                reasons: List<String>.from(match['match_reasons'] ?? []),
                onTap: () {
                  final type = match['type'];
                  final id = match['id'];
                  final jobProvider = context.read<JobProvider>();

                  try {
                    if (type == 'job') {
                      final job =
                          jobProvider.jobPosts.firstWhere((j) => j.id == id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailsScreen(post: job),
                        ),
                      );
                    } else if (type == 'project') {
                      final project = jobProvider.projectPosts
                          .firstWhere((p) => p.id == id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailsScreen(post: project),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Navigation Error: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Could not find the original post.")),
                    );
                  }
                },
              );
            },
            childCount: _matches.length,
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

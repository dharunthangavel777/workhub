import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../widgets/job_card.dart';
import '../shared/job_details_screen.dart';

import '../../../data/models/job_post_model.dart';
import '../../../data/models/project_post_model.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../widgets/promo_card.dart';
import '../auth/unified_login_screen.dart';
import '../settings/become_owner_screen.dart';

class JobFeedScreen extends StatelessWidget {
  const JobFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final user = context.watch<AuthProvider>().userModel;
    final activeMode = user?.activeMode ?? 'job';

    final posts = activeMode == 'job'
        ? jobProvider.jobPosts
            .where((p) => p.status != 'filled' && p.status != 'closed')
            .toList()
        : jobProvider.projectPosts
            .where((p) => p.status != 'filled' && p.status != 'closed')
            .toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          _buildAppBar(context, user),
          _buildSearchField(),
          if (posts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  "No opportunities available yet.",
                  style: TextStyle(color: CustomColors.textMuted),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Inject Promo Card only once at index 1
                    if (index == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PromoCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BecomeOwnerScreen(),
                            ),
                          ),
                        ),
                      );
                    }

                    // Calculate the actual post index
                    // index 0 -> post 0
                    // index 1 -> Promo
                    // index 2 -> post 1
                    final postIndex = index > 1 ? index - 1 : index;
                    if (postIndex >= posts.length) return null;

                    final post = posts[postIndex];
                    final isJob = post is JobPostModel;
                    final isBookmarked = isJob
                        ? (user?.savedJobIds.contains(post.id) ?? false)
                        : (user?.savedProjectIds
                                .contains((post as ProjectPostModel).id) ??
                            false);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => _showJobDetails(context, post),
                        child: isJob
                            ? JobCard.fromJobPost(post).copyWith(
                                isBookmarked: isBookmarked,
                                onBookmarkToggle: () => _toggleSave(
                                  context,
                                  post.id,
                                  'job',
                                  isBookmarked,
                                ),
                              )
                            : JobCard.fromProjectPost(post as ProjectPostModel)
                                .copyWith(
                                isBookmarked: isBookmarked,
                                onBookmarkToggle: () => _toggleSave(
                                  context,
                                  post.id,
                                  'project',
                                  isBookmarked,
                                ),
                              ),
                      ),
                    );
                  },
                  childCount: posts.length + (posts.isEmpty ? 0 : 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic user) {
    return SliverAppBar(
      floating: true,
      expandedHeight: 180,
      backgroundColor: CustomColors.lightBg,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              const Text("Mode:",
                  style:
                      TextStyle(color: CustomColors.textMuted, fontSize: 12)),
              const SizedBox(width: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'job',
                      label: Text('Job', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.work_outline, size: 14)),
                  ButtonSegment(
                      value: 'freelancer',
                      label: Text('Free', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.bolt, size: 14)),
                ],
                selected: {user?.activeMode ?? 'job'},
                onSelectionChanged: (newSelection) async {
                  if (context.read<AuthProvider>().isGuest) {
                    _showGuestLoginPrompt(context);
                    return;
                  }
                  final newMode = newSelection.first;
                  await context.read<AuthProvider>().switchWorkerMode(newMode);
                  if (context.mounted) {
                    context.read<JobProvider>().updateMode(newMode);
                  }
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return CustomColors.primaryBlue.withValues(alpha: 0.2);
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                user?.activeMode == 'freelancer'
                    ? "Project Feed"
                    : "Discover Gigs",
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                user?.activeMode == 'freelancer'
                    ? "Bid on projects and earn more"
                    : "Hand-picked opportunities for you",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: CustomColors.textMuted),
            hintText: "Search titles, skills...",
          ),
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context, dynamic post) {
    if (context.read<AuthProvider>().isGuest) {
      _showGuestLoginPrompt(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailsScreen(post: post)),
    );
  }

  void _toggleSave(
      BuildContext context, String id, String type, bool isCurrentlySaved) {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      _showGuestLoginPrompt(context);
      return;
    }

    context.read<JobProvider>().toggleSaveOpportunity(
          userId: auth.userModel!.uid,
          opportunityId: id,
          type: type,
          isSaving: !isCurrentlySaved,
        );
  }

  void _showGuestLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text(
          "Unlock Full Access",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Log in to view complete job details, message owners, and apply for opportunities.",
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Maybe Later", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                const Text("Login Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

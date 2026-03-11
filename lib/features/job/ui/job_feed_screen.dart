import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:work_hub/core/theme/custom_colors.dart';
import 'package:work_hub/core/theme/text_style_helper.dart';
import 'package:work_hub/constants/app_strings.dart';

import 'package:work_hub/features/job/ui/job_details_screen.dart';
import 'package:work_hub/features/job/ui/widgets/job_card.dart';
import 'package:work_hub/core/shared_widgets/universal_skeleton.dart';
import 'package:work_hub/features/auth/ui/unified_login_screen.dart';

import 'package:work_hub/features/job/logic/job_controller.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/core/orchestration/enterprise_state.dart';

class JobFeedScreen extends StatelessWidget {
  const JobFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final user = context.watch<AuthProvider>().userModel;
    final activeMode = user?.activeMode ?? 'job';

    final posts = activeMode == 'job'
        ? jobProvider.jobPosts
            .where((p) =>
                p.status != 'filled' &&
                p.status != 'closed' &&
                !jobProvider.appliedJobIds.contains(p.id))
            .toList()
        : jobProvider.projectPosts
            .where((p) =>
                p.status != 'filled' &&
                p.status != 'closed' &&
                !jobProvider.appliedProjectIds.contains(p.id))
            .toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          _buildAppBar(context, user),
          _buildSearchField(),
          if (jobProvider.feedState.status == UnifiedState.loading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => UniversalSkeleton.card(),
                  childCount: 3,
                ),
              ),
            )
          else if (posts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.noOpportunities,
                      style: TextStyleHelper.instance.body14Regular,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Calculate the actual post index
                    // index 0 -> post 0
                    // index 1 -> Promo
                    // index 2 -> post 1
                    final postIndex = index > 1 ? index - 1 : index;
                    if (postIndex >= posts.length) return null;

                    final post = posts[postIndex];
                    final isJob = activeMode == 'job';
                    final isBookmarked = isJob
                        ? (user?.savedJobIds.contains(post.id) ?? false)
                        : (user?.savedProjectIds.contains(post.id) ?? false);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OpenContainer(
                        closedElevation: 0,
                        openElevation: 0,
                        closedColor: Colors.transparent,
                        middleColor: Colors.transparent,
                        openColor: Colors.transparent,
                        closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        transitionDuration: const Duration(milliseconds: 500),
                        openBuilder: (context, action) {
                          if (context.read<AuthProvider>().isGuest) {
                            return const UnifiedLoginScreen();
                          }
                          return JobDetailsScreen(post: post);
                        },
                        closedBuilder: (context, action) {
                          return isJob
                              ? JobCard.fromJobPost(post).copyWith(
                                  isBookmarked: isBookmarked,
                                  onBookmarkToggle: () => _toggleSave(
                                    context,
                                    post.id,
                                    'job',
                                    isBookmarked,
                                  ),
                                )
                              : JobCard.fromProjectPost(post).copyWith(
                                  isBookmarked: isBookmarked,
                                  onBookmarkToggle: () => _toggleSave(
                                    context,
                                    post.id,
                                    'project',
                                    isBookmarked,
                                  ),
                                );
                        },
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
              const Text(AppStrings.modeLabel,
                  style:
                      TextStyle(color: CustomColors.textMuted, fontSize: 12)),
              const SizedBox(width: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                      value: 'job',
                      label: Text(AppStrings.jobLabel,
                          style: TextStyleHelper.instance.body12Medium),
                      icon: const Icon(Icons.work_outline, size: 14)),
                  ButtonSegment(
                      value: 'freelancer',
                      label: Text(AppStrings.freeLabel,
                          style: TextStyleHelper.instance.body12Medium),
                      icon: const Icon(Icons.bolt, size: 14)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                user?.activeMode == 'freelancer'
                    ? AppStrings.projectFeed
                    : AppStrings.discoverJobs,
                style: TextStyleHelper.instance.headline30Bold
                    .copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                user?.activeMode == 'freelancer'
                    ? AppStrings.projectFeedSubtitle
                    : AppStrings.jobFeedSubtitle,
                style: TextStyleHelper.instance.body14Regular,
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
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            hintText: AppStrings.searchPlaceholder,
            filled: true,
            fillColor: CustomColors.primaryBlue.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
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
        title: Text(
          AppStrings.guestPromptTitle,
          style: TextStyleHelper.instance.body16Bold,
        ),
        content: Text(
          AppStrings.guestPromptContent,
          style: TextStyleHelper.instance.body14Regular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.maybeLater,
                style: TextStyleHelper.instance.body14Medium
                    .copyWith(color: Colors.grey)),
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
            child: Text(AppStrings.loginNow,
                style: TextStyleHelper.instance.body14Bold
                    .copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

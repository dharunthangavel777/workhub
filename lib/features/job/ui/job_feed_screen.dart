import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/constants/app_strings.dart';

import 'package:work_hub/features/job/ui/job_details_screen.dart';
import 'package:work_hub/features/job/ui/widgets/job_card.dart';
import 'package:work_hub/core/shared_widgets/universal_skeleton.dart';
import 'package:work_hub/features/auth/ui/unified_login_screen.dart';
import 'package:work_hub/features/freelance/ui/worker_projects_screen.dart';

import 'package:work_hub/features/job/logic/job_controller.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/core/orchestration/enterprise_state.dart';
import 'package:work_hub/core/widgets/animated_typing_search_view.dart';

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

    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// BLUE HEADER SECTION
            _buildBlueHeader(context, user),

            SizedBox(height: 16.h),

            /// WHITE BODY SECTION
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: appTheme.white_A700_01,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: CustomScrollView(
                  slivers: [
                    if (jobProvider.feedState.status == UnifiedState.loading)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
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
                          child: Text(
                            AppStrings.noOpportunities,
                            style: TextStyleHelper.instance.body14Regular
                                .copyWith(color: appTheme.gray_500),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= posts.length) return null;

                              final post = posts[index];
                              final isJob = activeMode == 'job';
                              final isBookmarked = isJob
                                  ? (user?.savedJobIds.contains(post.id) ?? false)
                                  : (user?.savedProjectIds.contains(post.id) ?? false);

                              return Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: OpenContainer(
                                  closedElevation: 0,
                                  openElevation: 0,
                                  closedColor: Colors.transparent,
                                  middleColor: Colors.transparent,
                                  openColor: Colors.transparent,
                                  closedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.h),
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
                            childCount: posts.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueHeader(BuildContext context, dynamic user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  child: AnimatedTypingSearchView(
                    backgroundColor: Colors.white,
                    borderColor: Colors.white.withValues(alpha: 0.2),
                    iconColor: CustomColors.primaryBlue,
                    textColor: CustomColors.darkText,
                    hintColor: appTheme.gray_500,
                    showShadow: true,
                    onChanged: (value) {
                      // Handle search
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WorkerProjectsScreen()),
                  );
                },
                child: Container(
                  height: 54.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.h),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        color: CustomColors.primaryBlue,
                        size: 20.h,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Applied",
                        style: TextStyleHelper.instance.body14Bold
                            .copyWith(color: CustomColors.primaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
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
                borderRadius: BorderRadius.circular(12.h),
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
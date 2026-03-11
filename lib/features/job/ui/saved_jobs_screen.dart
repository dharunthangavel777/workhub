import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/job/ui/job_details_screen.dart';
import 'package:work_hub/features/job/ui/widgets/job_card.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/features/job/logic/job_controller.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final user = auth.userModel;

    // Guest / Null user logic remains unchanged
    if (user == null || auth.isGuest) {
      return Scaffold(
        backgroundColor: CustomColors.primaryBlue,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, "Saved Opportunities"),
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
                  child: const Center(
                    child: Text("Login to see your saved opportunities"),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeMode = user.activeMode;
    final savedIds = activeMode == 'job' ? user.savedJobIds : user.savedProjectIds;

    final savedPosts = activeMode == 'job'
        ? jobProvider.jobPosts.where((p) => savedIds.contains(p.id)).toList()
        : jobProvider.projectPosts
            .where((p) => savedIds.contains(p.id))
            .toList();

    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// HEADER
            _buildHeader(context, activeMode == 'job' ? "Saved Jobs" : "Saved Projects"),

            SizedBox(height: 16.h),

            /// WHITE BODY
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
                child: savedPosts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                        itemCount: savedPosts.length,
                        itemBuilder: (context, index) {
                          final post = savedPosts[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: activeMode == 'job'
                                ? JobCard.fromJobPost(post).copyWith(
                                    isBookmarked: true,
                                    onTap: () => _navigateToDetails(context, post),
                                    onBookmarkToggle: () => _toggleSave(
                                      context,
                                      post.id,
                                      'job',
                                    ),
                                  )
                                : JobCard.fromProjectPost(post).copyWith(
                                    isBookmarked: true,
                                    onTap: () => _navigateToDetails(context, post),
                                    onBookmarkToggle: () => _toggleSave(
                                      context,
                                      post.id,
                                      'project',
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            title,
            style: TextStyleHelper.instance.headline22Bold.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 64.h,
            color: appTheme.gray_300,
          ),
          SizedBox(height: 16.h),
          Text(
            "No saved items yet",
            style: TextStyleHelper.instance.body14Medium
                .copyWith(color: appTheme.gray_500),
          ),
        ],
      ),
    );
  }

  void _toggleSave(BuildContext context, String id, String type) {
    final auth = context.read<AuthProvider>();
    context.read<JobProvider>().toggleSaveOpportunity(
          userId: auth.userModel!.uid,
          opportunityId: id,
          type: type,
          isSaving: false, // Unsaving from this screen
        );
  }

  void _navigateToDetails(BuildContext context, dynamic post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(post: post),
      ),
    );
  }
}
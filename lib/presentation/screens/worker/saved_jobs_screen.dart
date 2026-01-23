import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/theme/custom_colors.dart';
import '../../widgets/job_card.dart';
import 'package:work_hub/data/models/job_post_model.dart';
import 'package:work_hub/data/models/project_post_model.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import '../shared/job_details_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final user = auth.userModel;

    if (user == null || auth.isGuest) {
      return const Scaffold(
        body: Center(
          child: Text("Login to see your saved opportunities"),
        ),
      );
    }

    final activeMode = user.activeMode;
    final savedIds =
        activeMode == 'job' ? user.savedJobIds : user.savedProjectIds;

    final savedPosts = activeMode == 'job'
        ? jobProvider.jobPosts.where((p) => savedIds.contains(p.id)).toList()
        : jobProvider.projectPosts
            .where((p) => savedIds.contains(p.id))
            .toList();

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: Text(
          activeMode == 'job' ? "Saved Jobs" : "Saved Projects",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: CustomColors.darkText,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: savedPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_outline,
                          size: 64,
                          color: CustomColors.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No saved items yet",
                          style: TextStyle(color: CustomColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: savedPosts.length,
                    itemBuilder: (context, index) {
                      final post = savedPosts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  JobDetailsScreen(post: post),
                            ),
                          ),
                          child: activeMode == 'job'
                              ? JobCard.fromJobPost(post as JobPostModel)
                                  .copyWith(
                                  isBookmarked: true,
                                  onBookmarkToggle: () => _toggleSave(
                                    context,
                                    post.id,
                                    'job',
                                  ),
                                )
                              : JobCard.fromProjectPost(
                                      post as ProjectPostModel)
                                  .copyWith(
                                  isBookmarked: true,
                                  onBookmarkToggle: () => _toggleSave(
                                    context,
                                    post.id,
                                    'project',
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
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
}

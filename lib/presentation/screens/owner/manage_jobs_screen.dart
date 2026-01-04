import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/models/job_post_model.dart';
import '../../../data/models/project_post_model.dart';
import 'create_job_screen.dart';
import 'applicants_list_screen.dart';
import '../shared/job_details_screen.dart';
import '../shared/project_dashboard_screen.dart';

class ManageJobsScreen extends StatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  State<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen> {
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<JobProvider>().listenToProjects(user.uid, true);
        context.read<JobProvider>().listenToMyPosts(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final activeMode = authProvider.userModel?.activeMode ?? 'job';

    if (jobProvider.activeMode != activeMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<JobProvider>().updateMode(activeMode);
      });
    }

    if (user?.uid != _lastUserId) {
      _lastUserId = user?.uid;
      if (user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<JobProvider>().listenToProjects(user.uid, true);
          context.read<JobProvider>().listenToMyPosts(user.uid);
        });
      }
    }

    final ownerJobs = activeMode == 'job'
        ? jobProvider.myJobPosts
        : jobProvider.myProjectPosts;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text("Your Listings"),
        backgroundColor: CustomColors.lightBg,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'job',
                  label: Text('Job Posts'),
                  icon: Icon(Icons.work_outline),
                ),
                ButtonSegment(
                  value: 'freelancer',
                  label: Text('Project Posts'),
                  icon: Icon(Icons.rocket_launch_outlined),
                ),
              ],
              selected: {activeMode},
              onSelectionChanged: (Set<String> newSelection) {
                final newMode = newSelection.first;
                context.read<AuthProvider>().switchWorkerMode(newMode);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return CustomColors.primaryBlue;
                  }
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return CustomColors.textMuted;
                }),
              ),
            ),
          ),
        ),
      ),
      body: ownerJobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: CustomColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No jobs posted yet",
                    style: TextStyle(
                      color: CustomColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateJobScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.postJob),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: ownerJobs.length,
              itemBuilder: (context, index) {
                final job = ownerJobs[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailsScreen(post: job),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CustomColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              job is JobPostModel
                                  ? job.jobTitle
                                  : (job as ProjectPostModel).projectTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CustomColors.darkText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ((job as dynamic).status == 'filled' ||
                                        (job as dynamic).status == 'closed')
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ((job as dynamic).status == 'filled' ||
                                        (job as dynamic).status == 'closed')
                                    ? "FILLED"
                                    : (job as dynamic).status.toUpperCase(),
                                style: TextStyle(
                                  color: ((job as dynamic).status == 'filled' ||
                                          (job as dynamic).status == 'closed')
                                      ? Colors.blue
                                      : Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${(job as dynamic).applicants?.length ?? 0} Applicants",
                              style: const TextStyle(
                                color: CustomColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                if (jobProvider.projects.any(
                                  (p) => p.jobId == (job as dynamic).id,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        final project =
                                            jobProvider.projects.firstWhere(
                                          (p) => p.jobId == (job as dynamic).id,
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProjectDashboardScreen(
                                              project: project,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.dashboard_outlined,
                                        size: 18,
                                      ),
                                      label: const Text("Dashboard"),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ApplicantsListScreen(
                                        job: job,
                                        mode: activeMode,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.manage_accounts,
                                    size: 18,
                                  ),
                                  label: const Text("Applicants"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: CustomColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: ownerJobs.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateJobScreen()),
              ),
              backgroundColor: CustomColors.primaryBlue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

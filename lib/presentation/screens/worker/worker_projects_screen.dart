import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/models/job_post_model.dart';
import '../shared/project_dashboard_screen.dart';
import '../../widgets/subscription_banner.dart';
import '../shared/job_details_screen.dart';

class WorkerProjectsScreen extends StatefulWidget {
  const WorkerProjectsScreen({super.key});

  @override
  State<WorkerProjectsScreen> createState() => _WorkerProjectsScreenState();
}

class _WorkerProjectsScreenState extends State<WorkerProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final user = context.read<AuthProvider>().userModel;
      if (user?.uid != null) {
        final jobProvider = context.read<JobProvider>();
        jobProvider.updateMode(user!.activeMode);
        jobProvider.fetchWorkerApplications(user.uid);
        jobProvider.listenToProjects(user.uid, false);
      }
      _isInit = false;
    } else {
      // Handle mode switch updates
      final user = context.watch<AuthProvider>().userModel;
      if (user?.uid != null) {
        final jobProvider = context.read<JobProvider>();
        if (jobProvider.activeMode != user!.activeMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            jobProvider.updateMode(user.activeMode);
            jobProvider.fetchWorkerApplications(user.uid);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userMode =
        context.watch<AuthProvider>().userModel?.activeMode ?? 'job';
    final isFreelancer = userMode == 'freelancer';

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: Text(isFreelancer ? 'My Projects' : 'Job Applications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: isFreelancer
            ? TabBar(
                controller: _tabController,
                indicatorColor: CustomColors.primaryBlue,
                tabs: const [
                  Tab(text: 'Bids'),
                  Tab(text: 'Ongoing'),
                  Tab(text: 'Archive'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SubscriptionBanner(
              tier: context.watch<AuthProvider>().userModel?.subscriptionTier ??
                  "Basic",
            ),
          ),
          Expanded(
            child: isFreelancer
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _ApplicationsSection(),
                      _OngoingProjectsSection(isArchived: false),
                      _OngoingProjectsSection(isArchived: true),
                    ],
                  )
                : _ApplicationsSection(),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final applications = jobProvider.appliedJobs;

    if (jobProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (applications.isEmpty) {
      final userMode =
          context.read<AuthProvider>().userModel?.activeMode ?? 'job';
      return Center(
        child: Text(
          userMode == 'freelancer'
              ? "No active bids.\nStart bidding on projects!"
              : "No job applications yet.\nStart looking for gigs!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: CustomColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final job = applications[index];
        return _ApplicationCard(job: job);
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final dynamic job;
  const _ApplicationCard({required this.job});

  @override
  Widget build(BuildContext context) {
    // Determine status from job metadata (assuming it's stored in applicants field for now)
    final userId = context.read<AuthProvider>().userModel?.uid;
    final applicationData = job.applicants?[userId];
    final status = applicationData?['status'] ?? 'Pending';

    Color statusColor;
    switch (status.toString().toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    final post = job;
    final title = post is JobPostModel ? post.jobTitle : post.projectTitle;
    final subtitle = post is JobPostModel ? post.companyName : "Client";
    final location = post is JobPostModel ? post.jobLocation : "Remote";
    final budget = post is JobPostModel
        ? "${post.salaryMin}-${post.salaryMax} ${post.salaryType}"
        : "₹${post.budgetMin} - ₹${post.budgetMax}";

    return GestureDetector(
      onTap: () {
        if (status.toString().toLowerCase() == 'approved') {
          final jobProvider = context.read<JobProvider>();
          final project = jobProvider.projects
              .where(
                  (p) => p.jobId == (post is JobPostModel ? post.id : post.id))
              .firstOrNull;

          if (project != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDashboardScreen(project: project),
              ),
            );
            return;
          }
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailsScreen(post: post)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: CustomColors.darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: CustomColors.primaryBlue,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: CustomColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    color: CustomColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  budget,
                  style: const TextStyle(
                    color: CustomColors.darkText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OngoingProjectsSection extends StatelessWidget {
  final bool isArchived;
  const _OngoingProjectsSection({required this.isArchived});

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final projects =
        isArchived ? jobProvider.archivedProjects : jobProvider.ongoingProjects;

    if (projects.isEmpty) {
      return Center(
        child: Text(
          isArchived
              ? "No archived projects yet."
              : "No ongoing projects yet.\nOnce hired, your projects will appear here.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: CustomColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectCard(project: project);
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final dynamic project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDashboardScreen(project: project),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(
                      color: CustomColors.darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "${(project.progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: CustomColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CustomColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: project.progress,
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(
                CustomColors.primaryBlue,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/theme/custom_colors.dart';
import 'package:work_hub/constants/app_strings.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/data/models/job_post_model.dart';
import 'package:work_hub/data/models/project_post_model.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<JobProvider>().listenToProjects(user.uid, true);
        context.read<JobProvider>().listenToMyPosts(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final activeMode = user?.activeMode ?? 'job';

    // Sync provider mode if it drifts from user model
    if (jobProvider.activeMode != activeMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<JobProvider>().updateMode(activeMode);
      });
    }

    // Refresh if user changed
    if (user?.uid != _lastUserId) {
      _lastUserId = user?.uid;
      if (user != null) _fetchData();
    }

    final ownerJobs = activeMode == 'job'
        ? jobProvider.myJobPosts
        : jobProvider.myProjectPosts;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text(
          "Your Listings",
          style: TextStyle(
              color: CustomColors.darkText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
        ),
        elevation: 0,
        backgroundColor: CustomColors.lightBg,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded,
                color: CustomColors.primaryBlue),
            tooltip: "Refresh listings",
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildModeSelector(activeMode),
          ),
        ),
      ),
      body: ownerJobs.isEmpty
          ? _buildEmptyState()
          : _buildJobsList(ownerJobs, activeMode, jobProvider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateJobScreen()),
        ),
        backgroundColor: CustomColors.primaryBlue,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        label: const Text(
          "Post New",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(String activeMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: "Job Posts",
            isSelected: activeMode == 'job',
            onTap: () => context.read<AuthProvider>().switchWorkerMode('job'),
          ),
          _ModeButton(
            label: "Project Posts",
            isSelected: activeMode != 'job',
            onTap: () =>
                context.read<AuthProvider>().switchWorkerMode('freelancer'),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: CustomColors.lightCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(
              Icons.work_history_outlined,
              size: 72,
              color: CustomColors.textMuted.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "No active listings found",
            style: TextStyle(
              color: CustomColors.darkText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Ready to hire? Create your first post.",
            style: TextStyle(color: CustomColors.textMuted, fontSize: 15),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateJobScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: CustomColors.primaryBlue.withOpacity(0.4),
            ),
            child: const Text(
              "Post a Listing",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(
      List<dynamic> ownerJobs, String activeMode, JobProvider provider) {
    return ListView.separated(
      padding:
          const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra padding for FAB
      itemCount: ownerJobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final job = ownerJobs[index];
        return _JobListingCard(
          job: job,
          activeMode: activeMode,
          jobProvider: provider,
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? CustomColors.primaryBlue
                    : CustomColors.textMuted,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobListingCard extends StatelessWidget {
  final dynamic job;
  final String activeMode;
  final JobProvider jobProvider;

  const _JobListingCard({
    required this.job,
    required this.activeMode,
    required this.jobProvider,
  });

  @override
  Widget build(BuildContext context) {
    final title = job is JobPostModel
        ? job.jobTitle
        : (job as ProjectPostModel).projectTitle;
    final status = job.status ?? 'open';
    final applicantsCount = job.applicants?.length ?? 0;
    final bool isClosed = status == 'filled' || status == 'closed';
    final budget = job is JobPostModel
        ? job.salaryRange
        : (job as ProjectPostModel).budget;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobDetailsScreen(post: job)),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Container(
                      height: 50,
                      width: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (job is JobPostModel
                                    ? job.companyLogo
                                    : (job as ProjectPostModel).companyLogo) !=
                                null
                            ? Image.network(
                                job is JobPostModel
                                    ? job.companyLogo!
                                    : (job as ProjectPostModel).companyLogo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.business,
                                        color: CustomColors.textMuted),
                              )
                            : const Icon(Icons.business,
                                color: CustomColors.textMuted),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: CustomColors.darkText,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            budget ?? "No budget specified",
                            style: const TextStyle(
                              color: CustomColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(isClosed, status),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "APPLICANTS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: CustomColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.people_rounded,
                                size: 16, color: CustomColors.primaryBlue),
                            const SizedBox(width: 6),
                            Text(
                              "$applicantsCount Interests",
                              style: const TextStyle(
                                color: CustomColors.darkText,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Dashboard Action (Only if project exists for this job)
                        if (jobProvider.projects.any((p) => p.jobId == job.id))
                          _SmallActionButton(
                            icon: Icons.analytics_outlined,
                            label: "Dashboard",
                            color: Colors.green,
                            onPressed: () {
                              final project = jobProvider.projects
                                  .firstWhere((p) => p.jobId == job.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProjectDashboardScreen(project: project),
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 10),
                        // Applicants Action
                        _SmallActionButton(
                          icon: Icons.person_search_rounded,
                          label: "Applicants",
                          color: CustomColors.primaryBlue,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicantsListScreen(
                                job: job,
                                mode: activeMode,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isClosed, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isClosed
            ? Colors.blue.withOpacity(0.08)
            : Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isClosed ? Colors.blue : Colors.green).withOpacity(0.1),
        ),
      ),
      child: Text(
        isClosed ? "FILLED" : status.toUpperCase(),
        style: TextStyle(
          color: isClosed ? Colors.blue : Colors.green,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 20),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            tooltip: label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        )
      ],
    );
  }
}

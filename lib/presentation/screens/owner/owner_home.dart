import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../data/models/project_model.dart';
import '../../../core/theme/custom_colors.dart';
import '../shared/project_dashboard_screen.dart';
import '../../widgets/subscription_banner.dart';

class OwnerHome extends StatefulWidget {
  const OwnerHome({super.key});

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
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
    final user = context.watch<AuthProvider>().userModel;
    final jobProvider = context.watch<JobProvider>();

    if (user?.uid != _lastUserId) {
      _lastUserId = user?.uid;
      if (user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<JobProvider>().listenToProjects(user.uid, true);
          context.read<JobProvider>().listenToMyPosts(user.uid);
        });
      }
    }

    final ownerJobs = [
      ...jobProvider.myJobPosts,
      ...jobProvider.myProjectPosts
    ];
    final activeProjects =
        jobProvider.projects.where((p) => p.status == 'ongoing').toList();
    final completedProjects =
        jobProvider.projects.where((p) => p.status == 'completed').toList();

    double totalSpent = 0;
    for (var project in jobProvider.projects) {
      project.payments?.forEach((key, value) {
        if (value['status'] == 'released') {
          totalSpent += (value['amount'] ?? 0);
        }
      });
    }

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      body: Container(
        color: CustomColors.lightBg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user?.managerName ?? "Owner"),
                const SizedBox(height: 24),
                SubscriptionBanner(tier: user?.subscriptionTier ?? "Starter"),
                const SizedBox(height: 32),
                const Text(
                  "Business Overview",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: CustomColors.darkText,
                  ),
                ),
                const SizedBox(height: 20),
                _buildOverviewSection(
                  context,
                  totalJobs: ownerJobs.length.toString(),
                  activeGigs: activeProjects.length.toString(),
                  completed: completedProjects.length.toString(),
                  spent: "₹${(totalSpent / 1000).toStringAsFixed(1)}k",
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ongoing Projects",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.darkText,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/manage-jobs'),
                      child: const Text(
                        "View All",
                        style: TextStyle(color: CustomColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildOngoingProjectsList(context, activeProjects),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back,",
              style: TextStyle(color: CustomColors.textMuted, fontSize: 16),
            ),
            Text(
              name,
              style: const TextStyle(
                color: CustomColors.darkText,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: CustomColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: IconButton(
            icon: const Icon(
              FontAwesomeIcons.solidBell,
              color: CustomColors.primaryBlue,
              size: 20,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection(
    BuildContext context, {
    required String totalJobs,
    required String activeGigs,
    required String completed,
    required String spent,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _OverviewCard(
          title: "Total Jobs",
          value: totalJobs,
          icon: FontAwesomeIcons.briefcase,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/manage-jobs'),
        ),
        _OverviewCard(
          title: "Active Gigs",
          value: activeGigs,
          icon: FontAwesomeIcons.rocket,
          color: Colors.green,
          onTap: () {},
        ),
        _OverviewCard(
          title: "Completed",
          value: completed,
          icon: FontAwesomeIcons.circleCheck,
          color: Colors.purple,
          onTap: () {},
        ),
        _OverviewCard(
          title: "Total Spent",
          value: spent,
          icon: FontAwesomeIcons.wallet,
          color: Colors.orange,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildOngoingProjectsList(
    BuildContext context,
    List<ProjectModel> projects,
  ) {
    if (projects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: const Text(
            "No ongoing projects",
            style: TextStyle(color: CustomColors.textMuted),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectProgressCard(
          title: project.title,
          worker:
              project.workerName ?? "Gigs Worker", // Show actual worker name
          progress: project.progress,
          status: project.status,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDashboardScreen(project: project),
              ),
            );
          },
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CustomColors.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CustomColors.darkText,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, color: CustomColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectProgressCard extends StatelessWidget {
  final String title;
  final String worker;
  final double progress;
  final String status;
  final VoidCallback onTap;

  const _ProjectProgressCard({
    required this.title,
    required this.worker,
    required this.progress,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CustomColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.darkText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CustomColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        color: CustomColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: CustomColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    worker,
                    style: const TextStyle(
                      color: CustomColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    status,
                    style: TextStyle(
                      color: progress == 1.0
                          ? Colors.green
                          : CustomColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.black.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    CustomColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/data/models/project_model.dart';
import 'package:work_hub/theme/custom_colors.dart';
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
    // Initial data fetch on mount
    _fetchUserData();
  }

  void _fetchUserData() {
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
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final jobProvider = context.watch<JobProvider>();

    // Handle user switching logic
    if (user?.uid != _lastUserId) {
      _lastUserId = user?.uid;
      if (user != null) {
        _fetchUserData();
      }
    }

    // Derived Data
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
        if (value is Map && value['status'] == 'released') {
          totalSpent += (value['amount'] ?? 0).toDouble();
        }
      });
    }

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchUserData(),
          color: CustomColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user?.managerName ?? "Owner"),
                const SizedBox(height: 24),
                
                // Subscription Status
                SubscriptionBanner(tier: user?.subscriptionTier ?? "Starter"),
                const SizedBox(height: 32),
                
                // Section Title
                const Text(
                  "Business Overview",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: CustomColors.darkText,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Stats Grid
                _buildOverviewSection(
                  context,
                  totalJobs: ownerJobs.length.toString(),
                  activeGigs: activeProjects.length.toString(),
                  completed: completedProjects.length.toString(),
                  spent: "₹${(totalSpent / 1000).toStringAsFixed(1)}k",
                ),
                
                const SizedBox(height: 40),
                
                // Ongoing Projects Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Ongoing Projects",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: CustomColors.darkText,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/manage-jobs'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "View All",
                        style: TextStyle(
                          color: CustomColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Project List
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back,",
                style: TextStyle(
                  color: CustomColors.textMuted.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  color: CustomColors.darkText,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildCircularIconButton(
          icon: FontAwesomeIcons.solidBell,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: CustomColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: CustomColors.primaryBlue, size: 18),
        onPressed: onPressed,
      ),
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
      childAspectRatio: 1.15,
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: CustomColors.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
        ),
        child: const Column(
          children: [
            Icon(FontAwesomeIcons.folderOpen, color: CustomColors.textMuted, size: 32),
            SizedBox(height: 12),
            Text(
              "No projects currently in progress",
              style: TextStyle(
                color: CustomColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectProgressCard(
          title: project.title,
          worker: project.workerName ?? "Gigs Worker",
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CustomColors.lightCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: CustomColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CustomColors.textMuted,
                ),
              ),
            ],
          ),
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
      decoration: BoxDecoration(
        color: CustomColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: CustomColors.darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: CustomColors.primaryBlue.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 14, color: CustomColors.primaryBlue),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    worker,
                    style: const TextStyle(
                      color: CustomColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      color: CustomColors.primaryBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [CustomColors.primaryBlue, Color(0xFF64B5F6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: CustomColors.primaryBlue.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bool isDone = progress >= 1.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withOpacity(0.1) : CustomColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isDone ? "Completed" : status.toUpperCase(),
        style: TextStyle(
          color: isDone ? Colors.green : CustomColors.primaryBlue,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
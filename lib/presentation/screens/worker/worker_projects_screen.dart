import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/models/job_post_model.dart';
import '../shared/project_dashboard_screen.dart';
import '../shared/job_details_screen.dart';
import '../../widgets/become_hirer_banner.dart';

class WorkerProjectsScreen extends StatefulWidget {
  const WorkerProjectsScreen({super.key});

  @override
  State<WorkerProjectsScreen> createState() => _WorkerProjectsScreenState();
}

class _WorkerProjectsScreenState extends State<WorkerProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final user = context.read<AuthProvider>().userModel;
      if (user?.uid != null) {
        final jobProvider = context.read<JobProvider>();
        jobProvider.updateMode(user!.activeMode);
        jobProvider.listenToWorkerApplications(user.uid);
        jobProvider.listenToProjects(user.uid, false);
      }
      _isInit = false;
    } else {
      final user = context.watch<AuthProvider>().userModel;
      if (user?.uid != null) {
        final jobProvider = context.read<JobProvider>();
        if (jobProvider.activeMode != user!.activeMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            jobProvider.updateMode(user.activeMode);
            jobProvider.listenToWorkerApplications(user.uid);
            jobProvider.listenToProjects(user.uid, false);
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
      backgroundColor: appTheme.white_A700_01,
      appBar: AppBar(
        title: Text(
          isFreelancer ? 'My Projects' : 'Job Applications',
          style: TextStyleHelper.instance.headline22Bold.copyWith(
            color: appTheme.gray_900,
          ),
        ),
        backgroundColor: appTheme.white_A700_01,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            child: const BecomeHirerBanner(),
          ),
          if (isFreelancer)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: TabBar(
                controller: _tabController,
                indicatorColor: appTheme.indigo_A700,
                labelColor: appTheme.indigo_A700,
                unselectedLabelColor: appTheme.gray_500,
                indicatorWeight: 3,
                labelStyle: TextStyleHelper.instance.body14Bold,
                unselectedLabelStyle: TextStyleHelper.instance.body14Medium,
                tabs: const [
                  Tab(text: 'Bids'),
                  Tab(text: 'Ongoing'),
                  Tab(text: 'Archive'),
                ],
              ),
            ),
          SizedBox(height: 16.h),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgSearch, // Fallback to search icon
              height: 80.h,
              color: appTheme.gray_300,
            ),
            SizedBox(height: 16.h),
            Text(
              userMode == 'freelancer'
                  ? "No active bids.\nStart bidding on projects!"
                  : "No job applications yet.\nStart looking for gigs!",
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray_500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
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
        statusColor = appTheme.orange_600;
    }

    final post = job;
    final title = post is JobPostModel ? post.jobTitle : post.projectTitle;
    final subtitle = post is JobPostModel ? post.companyName : "Client Project";
    final location = post is JobPostModel ? post.jobLocation : "Remote";
    final budget = post is JobPostModel
        ? "${post.salaryMin}-${post.salaryMax}"
        : "₹${post.budgetMin} - ₹${post.budgetMax}";
    final logo = post is JobPostModel ? post.companyLogo : post.companyLogo;

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
                  builder: (context) =>
                      ProjectDashboardScreen(project: project)),
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
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: appTheme.white_A700_01,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: appTheme.gray_200),
          boxShadow: [
            BoxShadow(
              color: appTheme.gray_900.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 48.h,
                  width: 48.h,
                  decoration: BoxDecoration(
                    color: appTheme.gray_50,
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.h),
                    child: CustomImageView(
                      imagePath: (logo != null && logo.isNotEmpty)
                          ? logo
                          : ImageConstant.imgImage4,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyleHelper.instance.body16Bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyleHelper.instance.body12Medium
                            .copyWith(color: appTheme.indigo_A700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: TextStyleHelper.instance.body12Bold
                        .copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant
                          .imgSearch, // Replace with location icon if available
                      height: 14.h,
                      color: appTheme.gray_400,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      location,
                      style: TextStyleHelper.instance.body12Medium
                          .copyWith(color: appTheme.gray_500),
                    ),
                  ],
                ),
                Text(
                  budget,
                  style: TextStyleHelper.instance.body14Bold
                      .copyWith(color: appTheme.gray_900),
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
          style: TextStyleHelper.instance.body14Medium
              .copyWith(color: appTheme.gray_500),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
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
            builder: (context) => ProjectDashboardScreen(project: project)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: appTheme.white_A700_01,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: appTheme.gray_200),
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
                    style: TextStyleHelper.instance.body16Bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${(project.progress * 100).toInt()}%",
                  style: TextStyleHelper.instance.body14Bold
                      .copyWith(color: appTheme.indigo_A700),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyleHelper.instance.body12Medium
                  .copyWith(color: appTheme.gray_500),
            ),
            SizedBox(height: 16.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.h),
              child: LinearProgressIndicator(
                value: project.progress,
                minHeight: 8.h,
                backgroundColor: appTheme.gray_100,
                valueColor: AlwaysStoppedAnimation<Color>(appTheme.indigo_A700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

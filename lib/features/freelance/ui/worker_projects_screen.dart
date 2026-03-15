import 'package:provider/provider.dart';
import 'package:qwok/core/config/app_export.dart';
import 'package:qwok/features/auth/logic/auth_controller.dart';
import 'package:qwok/features/job/logic/job_controller.dart';
import 'package:qwok/features/freelance/ui/project_dashboard_screen.dart';

import 'package:qwok/features/job/domain/models/job.dart';
import 'package:qwok/features/job/ui/widgets/job_card_skeleton.dart';
import 'package:qwok/features/job/ui/job_application_details_screen.dart';
import 'package:qwok/features/freelance/ui/freelance_bid_details_screen.dart';


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
        jobProvider.listenToProjects(user.uid);
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
            jobProvider.listenToProjects(user.uid);
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
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    isFreelancer ? 'My Projects' : 'Job Applications',
                    style: TextStyleHelper.instance.headline22Bold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            /// WHITE BODY
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: appTheme.whiteA70001,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: Column(
                  children: [
                    /// TAB BAR
                    if (isFreelancer) ...[
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: appTheme.indigoA700,
                          labelColor: appTheme.indigoA700,
                          unselectedLabelColor: appTheme.gray500,
                          indicatorWeight: 3,
                          labelStyle: TextStyleHelper.instance.body14Bold,
                          unselectedLabelStyle:
                              TextStyleHelper.instance.body14Medium,
                          tabs: const [
                            Tab(text: 'Bids'),
                            Tab(text: 'Ongoing'),
                            Tab(text: 'Archive'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],

                    /// CONTENT
                    Expanded(
                      child: isFreelancer
                          ? TabBarView(
                              controller: _tabController,
                              children: [
                                _ApplicationsSection(),
                                const _OngoingProjectsSection(
                                    isArchived: false),
                                const _OngoingProjectsSection(isArchived: true),
                              ],
                            )
                          : _ApplicationsSection(),
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
}

class _ApplicationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final userMode =
        context.watch<AuthProvider>().userModel?.activeMode ?? 'job';
    final isFreelancer = userMode == 'freelancer';

    final applications =
        isFreelancer ? jobProvider.appliedProjects : jobProvider.appliedJobs;

    if (jobProvider.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: ListView.builder(
          itemCount: 3,
          itemBuilder: (context, index) => const JobCardSkeleton(),
        ),
      );
    }

    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgSearch,
              height: 80.h,
              color: appTheme.gray300,
            ),
            SizedBox(height: 16.h),
            Text(
              userMode == 'freelancer'
                  ? "No active bids.\nStart bidding on projects!"
                  : "No job applications yet.\nStart looking for gigs!",
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding:
          EdgeInsets.only(left: 24.w, right: 24.w, top: 16.h, bottom: 100.h),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final job = applications[index];
        if (job.postType == 'project') {
          return _BidCard(project: job);
        }
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
    final Job post = job;
    final applicationData = post.applicants?[userId];
    final status = applicationData?['status'] ?? 'Pending';

    Color statusColor;
    switch (status.toString().toLowerCase()) {
      case 'approved':
      case 'shortlisted':
        statusColor = Colors.green;
        break;
      case 'waitlisted':
        statusColor = appTheme.orange600;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = appTheme.indigoA700;
    }

    final isJob = post.postType == 'job';

    final title = post.title;
    final subtitle = post.companyName ?? (isJob ? "Unknown" : "Client Project");
    final location = post.location;
    final budget = post.budgetMin != null
        ? "₹${post.budgetMin} - ₹${post.budgetMax}"
        : "Not Disclosed";
    final logo = post.companyLogo;

    return GestureDetector(
      onTap: () {
        if (status.toString().toLowerCase() == 'approved') {
          final jobProvider = context.read<JobProvider>();
          final project =
              jobProvider.projects.where((p) => p.jobId == post.id).firstOrNull;

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

        if (post.postType == 'project') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FreelanceBidDetailsScreen(post: post)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobApplicationDetailsScreen(post: post)),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: appTheme.whiteA70001,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: appTheme.gray200),
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
                    color: appTheme.gray50,
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
                            .copyWith(color: appTheme.indigoA700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
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
                    Icon(Icons.location_on_outlined,
                        size: 14.h, color: appTheme.gray400),
                    SizedBox(width: 4.w),
                    Text(
                      location,
                      style: TextStyleHelper.instance.body12Medium
                          .copyWith(color: appTheme.gray500),
                    ),
                  ],
                ),
                Text(
                  budget,
                  style: TextStyleHelper.instance.body14Bold
                      .copyWith(color: appTheme.gray900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final Job project;
  const _BidCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().userModel?.uid;
    final bidData = project.applicants?[userId];
    final status = bidData?['status'] ?? 'Pending';
    final bidAmount = bidData?['bidAmount'] ?? project.budgetMin;

    Color statusColor;
    switch (status.toString().toLowerCase()) {
      case 'approved':
      case 'hired':
        statusColor = Colors.green;
        break;
      case 'shortlisted':
        statusColor = appTheme.indigoA700;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        if (status.toString().toLowerCase() == 'approved' ||
            status.toString().toLowerCase() == 'hired') {
          final jobProvider = context.read<JobProvider>();
          final liveProject = jobProvider.projects
              .where((p) => p.jobId == project.id)
              .firstOrNull;

          if (liveProject != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ProjectDashboardScreen(project: liveProject)),
            );
            return;
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FreelanceBidDetailsScreen(post: project)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: appTheme.indigoA700.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24.h),
          border: Border.all(color: appTheme.indigoA700.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color: appTheme.whiteA70001,
                    borderRadius: BorderRadius.circular(12.h),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(Icons.gavel_rounded,
                      color: appTheme.indigoA700, size: 24.h),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: TextStyleHelper.instance.body16Bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Freelance Project • ${project.companyName ?? 'Private Client'}",
                        style: TextStyleHelper.instance.body12Medium
                            .copyWith(color: appTheme.gray600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.h),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: TextStyleHelper.instance.body10Bold
                        .copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: appTheme.whiteA70001,
                borderRadius: BorderRadius.circular(16.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("YOUR BID",
                          style: TextStyleHelper.instance.body10Medium
                              .copyWith(color: appTheme.gray500)),
                      Text("₹$bidAmount",
                          style: TextStyleHelper.instance.body16Bold
                              .copyWith(color: appTheme.indigoA700)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("COMPETITION",
                          style: TextStyleHelper.instance.body10Medium
                              .copyWith(color: appTheme.gray500)),
                      Text("${project.applicants?.length ?? 0} Bidders",
                          style: TextStyleHelper.instance.body14Bold
                              .copyWith(color: appTheme.gray900)),
                    ],
                  ),
                ],
              ),
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
              .copyWith(color: appTheme.gray500),
        ),
      );
    }

    return ListView.builder(
      padding:
          EdgeInsets.only(left: 24.w, right: 24.w, top: 16.h, bottom: 100.h),
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
          color: appTheme.whiteA70001,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: appTheme.gray200),
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
                      .copyWith(color: appTheme.indigoA700),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyleHelper.instance.body12Medium
                  .copyWith(color: appTheme.gray500),
            ),
            if (project.progress < 1.0) ...[
              SizedBox(height: 16.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.h),
                child: LinearProgressIndicator(
                  value: project.progress,
                  minHeight: 8.h,
                  backgroundColor: appTheme.gray100,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(appTheme.indigoA700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

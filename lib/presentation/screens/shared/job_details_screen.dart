import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/app_export.dart';
import '../../../data/models/job_post_model.dart';
import '../../../data/models/project_post_model.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../core/utils/skill_icon_utils.dart';
import 'project_dashboard_screen.dart';

class JobDetailsScreen extends StatelessWidget {
  final dynamic post; // Can be JobPostModel or ProjectPostModel

  const JobDetailsScreen({super.key, required this.post});

  bool get isJob => post is JobPostModel;
  JobPostModel get jobPost => post as JobPostModel;
  ProjectPostModel get projectPost => post as ProjectPostModel;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) {
      return Scaffold(
        backgroundColor: appTheme.white_A700_01,
        body: Center(
            child: CircularProgressIndicator(color: appTheme.indigo_A700)),
      );
    }

    final isFreelancer = user.activeMode == 'freelancer';
    final title = isJob ? jobPost.jobTitle : projectPost.projectTitle;
    final companyName = isJob
        ? jobPost.companyName
        : (projectPost.companyName ?? "Freelance Project");
    final logoUrl = isJob ? jobPost.companyLogo : projectPost.companyLogo;
    final ownerName = isJob ? jobPost.ownerName : projectPost.ownerName;

    return Scaffold(
      backgroundColor: appTheme.white_A700_01,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, logoUrl, companyName),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title Section
                  Text(
                    title,
                    style: TextStyleHelper.instance.headline22Bold.copyWith(
                      fontSize: 28.fSize,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        companyName,
                        style: TextStyleHelper.instance.body16Bold.copyWith(
                          color: appTheme.indigo_A700,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.verified, color: Colors.blue, size: 16.h),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Professional Highlight Grid
                  _buildSpecificationGrid(),

                  SizedBox(height: 40.h),

                  // Description & Roles
                  if (isJob)
                    ..._buildJobContent()
                  else
                    ..._buildProjectContent(),

                  SizedBox(height: 40.h),

                  // Skills Section with professional chips
                  _buildSkillsSection(),

                  SizedBox(height: 40.h),

                  // Recruiter Info Card
                  _buildPostedBySection(ownerName, companyName),

                  SizedBox(height: 120.h), // Safe area for bottom navigation
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, user, isFreelancer),
    );
  }

  Widget _buildAppBar(
      BuildContext context, String? logoUrl, String companyName) {
    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      elevation: 0,
      backgroundColor: appTheme.white_A700_01,
      leadingWidth: 70.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: appTheme.gray_900, size: 18.h),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    appTheme.indigo_A700,
                    appTheme.indigo_A700.withOpacity(0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 24.w,
              child: Hero(
                tag: 'logo-${isJob ? jobPost.id : projectPost.id}',
                child: Container(
                  height: 80.h,
                  width: 80.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.h),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                    border: Border.all(color: appTheme.gray_100, width: 1),
                  ),
                  padding: EdgeInsets.all(12.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.h),
                    child: (logoUrl != null && logoUrl.isNotEmpty)
                        ? CustomImageView(
                            imagePath: logoUrl, fit: BoxFit.contain)
                        : Center(
                            child: Text(
                              companyName[0].toUpperCase(),
                              style: TextStyleHelper.instance.headline22Bold
                                  .copyWith(
                                color: appTheme.indigo_A700,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationGrid() {
    return Container(
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildSpecItem(
                      Icons.work_outline,
                      "Exp. Level",
                      isJob
                          ? "${jobPost.experienceMin}-${jobPost.experienceMax} yrs"
                          : projectPost.experienceLevel)),
              _buildVerticalDivider(),
              Expanded(
                  child: _buildSpecItem(
                      Icons.payments_outlined,
                      "Salary/Budget",
                      isJob
                          ? "₹${jobPost.salaryMin}-${jobPost.salaryMax} / ${jobPost.salaryType}"
                          : "₹${projectPost.budgetMin}-${projectPost.budgetMax}")),
            ],
          ),
          Divider(height: 32.h, color: appTheme.gray_200),
          Row(
            children: [
              Expanded(
                  child: _buildSpecItem(
                      Icons.location_on_outlined,
                      "Location",
                      isJob
                          ? jobPost.jobLocation
                          : projectPost.projectLocation)),
              _buildVerticalDivider(),
              Expanded(
                  child: _buildSpecItem(Icons.calendar_month_outlined,
                      "Due Date", _getDeadlineText())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() =>
      Container(height: 40.h, width: 1, color: appTheme.gray_200);

  String _getDeadlineText() {
    final deadline = isJob ? jobPost.deadlineDate : projectPost.deadlineDate;
    if (deadline == null)
      return isJob ? jobPost.workMode : projectPost.projectType;
    return deadline.toLocal().toString().split(' ')[0];
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.h),
          decoration: BoxDecoration(
              color: appTheme.indigo_A700.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10.h)),
          child: Icon(icon, size: 18.h, color: appTheme.indigo_A700),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyleHelper.instance.body10Bold
                      .copyWith(color: appTheme.gray_400, letterSpacing: 0.5)),
              Text(value,
                  style: TextStyleHelper.instance.body12Bold
                      .copyWith(color: appTheme.gray_900),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostedBySection(String? ownerName, String companyName) {
    if (ownerName == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("About the Recruiter", style: TextStyleHelper.instance.body16Bold),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            color: appTheme.white_A700_01,
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(color: appTheme.gray_100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24.h,
                backgroundColor: appTheme.gray_50,
                child: Icon(Icons.person_pin,
                    color: appTheme.indigo_A700, size: 28.h),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(ownerName,
                            style: TextStyleHelper.instance.body14Bold),
                        if (isJob
                            ? jobPost.isVerified
                            : projectPost.isVerified) ...[
                          SizedBox(width: 4.w),
                          CustomImageView(
                            imagePath: ImageConstant.imgMdiTickDecagram,
                            height: 14.h,
                            width: 14.h,
                            color: appTheme.indigo_A700,
                          ),
                        ],
                      ],
                    ),
                    Text(isJob ? companyName : "Hiring Manager",
                        style: TextStyleHelper.instance.body12Medium
                            .copyWith(color: appTheme.gray_500)),
                    if (isJob) ...[
                      SizedBox(height: 4.h),
                      Text(
                        "${jobPost.companyIndustry} • ${jobPost.companySize ?? 'N/A'}",
                        style: TextStyleHelper.instance.body10Medium
                            .copyWith(color: appTheme.gray_400),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                    color: appTheme.gray_50,
                    borderRadius: BorderRadius.circular(12.h)),
                child: Text("Contact",
                    style: TextStyleHelper.instance.body12Bold
                        .copyWith(color: appTheme.indigo_A700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final skills = isJob ? jobPost.requiredSkills : projectPost.requiredSkills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Key Competencies", style: TextStyleHelper.instance.body16Bold),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: skills.map((s) {
            final iconUrl = SkillIconUtils.getIconUrl(s);
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: appTheme.white_A700_01,
                borderRadius: BorderRadius.circular(12.h),
                border: Border.all(color: appTheme.gray_200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconUrl != null) ...[
                    SvgPicture.network(iconUrl, width: 16.h, height: 16.h),
                    SizedBox(width: 8.w),
                  ],
                  Text(s,
                      style: TextStyleHelper.instance.body12Bold
                          .copyWith(color: appTheme.gray_900)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildJobContent() {
    return [
      _buildContentSection("Role Overview", jobPost.jobSummary),
      SizedBox(height: 32.h),
      _buildContentSection("Key Responsibilities", jobPost.responsibilities),
      if (jobPost.preferredSkills != null &&
          jobPost.preferredSkills!.isNotEmpty) ...[
        SizedBox(height: 32.h),
        _buildContentSection(
            "Preferred Qualifications", jobPost.preferredSkills!.join('\n• ')),
      ],
      SizedBox(height: 32.h),
      Text("Administrative Details",
          style: TextStyleHelper.instance.body16Bold),
      SizedBox(height: 16.h),
      _buildDetailRow("Contract Type", jobPost.employmentType),
      _buildDetailRow("Working Shift", jobPost.shiftType ?? "Standard"),
      _buildDetailRow("Vacancies", "${jobPost.openings}"),
      _buildDetailRow("Educational Criteria", jobPost.education),
      if (jobPost.maxApplications != null)
        _buildDetailRow("Application Limit", "${jobPost.maxApplications}"),
      _buildDetailRow("Applications", "${jobPost.applicationsCount}"),
    ];
  }

  List<Widget> _buildProjectContent() {
    return [
      _buildContentSection(
          "Project Objectives", projectPost.projectDescription),
      SizedBox(height: 32.h),
      if (projectPost.deliverables.isNotEmpty) ...[
        _buildContentSection(
            "Key Deliverables", projectPost.deliverables.join('\n• ')),
        SizedBox(height: 32.h),
      ],
      Text("Operational Framework", style: TextStyleHelper.instance.body16Bold),
      SizedBox(height: 16.h),
      _buildDetailRow("Estimated Duration", projectPost.projectDuration),
      _buildDetailRow("Collaboration Type", projectPost.projectType),
      if (projectPost.depositAmount != null)
        _buildDetailRow("Initial Deposit", "₹${projectPost.depositAmount}"),
      _buildDetailRow("Confidentiality (NDA)",
          projectPost.ndaRequired ? "Mandatory" : "Optional"),
      if (projectPost.maxApplications != null)
        _buildDetailRow("Proposal Limit", "${projectPost.maxApplications}"),
      _buildDetailRow("Proposals", "${projectPost.applicationsCount}"),
      if (projectPost.termsAndConditions != null) ...[
        SizedBox(height: 16.h),
        _buildContentSection(
            "Terms & Conditions", projectPost.termsAndConditions!),
      ],
    ];
  }

  Widget _buildContentSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyleHelper.instance.body16Bold),
        SizedBox(height: 12.h),
        Text(
          content,
          style: TextStyleHelper.instance.body14Medium.copyWith(
            color: appTheme.gray_600,
            height: 1.7,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyleHelper.instance.body12Medium
                  .copyWith(color: appTheme.gray_500)),
          Text(value,
              style: TextStyleHelper.instance.body12Bold
                  .copyWith(color: appTheme.gray_900)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, dynamic user, bool isFreelancer) {
    String? status = isJob
        ? jobPost.applicants?[user.uid]?['status']
        : projectPost.applicants?[user.uid]?['status'];
    bool isApproved = status?.toLowerCase() == 'approved';

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 34.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        border: Border(top: BorderSide(color: appTheme.gray_100)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -10))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: isApproved
            ? _buildDashboardButton(context)
            : _buildActionButton(context, user, isFreelancer),
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        final jobProvider = context.read<JobProvider>();
        final project = jobProvider.projects
            .where((p) => p.jobId == (isJob ? jobPost.id : projectPost.id))
            .firstOrNull;
        if (project != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ProjectDashboardScreen(project: project)));
        }
      },
      icon: Icon(Icons.dashboard_customize_outlined,
          color: Colors.white, size: 20.h),
      label: Text("Go to Workspace",
          style: TextStyleHelper.instance.body16Bold
              .copyWith(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade700,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
        elevation: 0,
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, dynamic user, bool isFreelancer) {
    final bool isClosed = _isPostClosed();
    return ElevatedButton(
      onPressed: isClosed
          ? null
          : () => _handleApplyAction(context, user, isFreelancer),
      style: ElevatedButton.styleFrom(
        backgroundColor: isClosed ? appTheme.gray_100 : appTheme.indigo_A700,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
        elevation: isClosed ? 0 : 4,
        shadowColor: appTheme.indigo_A700.withOpacity(0.3),
      ),
      child: Text(
        isClosed
            ? "Applications Closed"
            : (isFreelancer ? "Place a Proposal" : "Submit Application"),
        style: TextStyleHelper.instance.body16Bold
            .copyWith(color: isClosed ? appTheme.gray_400 : Colors.white),
      ),
    );
  }

  bool _isPostClosed() {
    final deadline = isJob ? jobPost.deadlineDate : projectPost.deadlineDate;
    final maxApps =
        isJob ? jobPost.maxApplications : projectPost.maxApplications;
    final currentApps = isJob
        ? (jobPost.applicants?.length ?? 0)
        : (projectPost.applicants?.length ?? 0);
    if (deadline != null && DateTime.now().isAfter(deadline)) return true;
    if (maxApps != null && currentApps >= maxApps) return true;
    return false;
  }

  void _handleApplyAction(
      BuildContext context, dynamic user, bool isFreelancer) {
    if (user.profileCompletion < 95) {
      _showIncompleteProfileDialog(context, user);
      return;
    }
    if (isFreelancer) {
      _showBidForm(context, post, user.uid, user.displayName);
    } else {
      _showApplyConfirmation(context, post, user.uid, user.displayName);
    }
  }

  void _showIncompleteProfileDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.white_A700_01,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
        title:
            Text("Action Required", style: TextStyleHelper.instance.body18Bold),
        content: Text(
            "To ensure high-quality applications, we require 95% profile completion. You are currently at ${user.profileCompletion}%.",
            style: TextStyleHelper.instance.body14Medium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Continue to Profile",
                  style: TextStyle(
                      color: appTheme.indigo_A700,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showApplyConfirmation(
      BuildContext context, dynamic post, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.white_A700_01,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
        title: Text("Submit Application?",
            style: TextStyleHelper.instance.body18Bold),
        content: Text(
            "Your professional profile and resume will be shared with the recruiter.",
            style: TextStyleHelper.instance.body14Medium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("Cancel", style: TextStyle(color: appTheme.gray_500))),
          ElevatedButton(
            onPressed: () async {
              if (isJob)
                await context
                    .read<JobProvider>()
                    .apply(jobPost.id, userId, userName);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Application submitted successfully!")));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.indigo_A700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.h))),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showBidForm(
      BuildContext context, dynamic post, String userId, String userName) {
    final amountController = TextEditingController();
    final proposalController = TextEditingController();
    final timelineController = TextEditingController();
    final projectPost = post as ProjectPostModel;
    List<Map<String, dynamic>> suggestedMilestones = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void calculateTotal() {
            double total = suggestedMilestones.fold(
                0, (sum, m) => sum + (m['amount'] as num).toDouble());
            amountController.text = total.toStringAsFixed(0);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
                color: appTheme.white_A700_01,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32.h))),
            padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w,
                MediaQuery.of(context).viewInsets.bottom + 24.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                              color: appTheme.gray_200,
                              borderRadius: BorderRadius.circular(2)))),
                  SizedBox(height: 24.h),
                  Text("Submit Proposal",
                      style: TextStyleHelper.instance.headline22Bold),
                  SizedBox(height: 8.h),
                  Text("Provide your best quote and timeline for this project.",
                      style: TextStyleHelper.instance.body12Medium
                          .copyWith(color: appTheme.gray_500)),
                  SizedBox(height: 32.h),
                  _buildBidField(amountController, "Contract Amount (₹)",
                      "Total project budget", Icons.payments_outlined,
                      isReadOnly: suggestedMilestones.isNotEmpty),
                  SizedBox(height: 20.h),
                  _buildBidField(timelineController, "Delivery Timeline",
                      "e.g. 14 Business Days", Icons.timer_outlined),
                  SizedBox(height: 20.h),
                  _buildBidField(
                      proposalController,
                      "Executive Summary",
                      "Briefly explain your relevant experience...",
                      Icons.description_outlined,
                      maxLines: 5),
                  SizedBox(height: 32.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Project Milestones",
                          style: TextStyleHelper.instance.body16Bold),
                      TextButton.icon(
                        onPressed: () => _showAddMilestoneDialog(context, (m) {
                          setModalState(() {
                            suggestedMilestones.add(m);
                            calculateTotal();
                          });
                        }),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text("Add Phase",
                            style: TextStyleHelper.instance.body14Bold
                                .copyWith(color: appTheme.indigo_A700)),
                      ),
                    ],
                  ),
                  if (suggestedMilestones.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: Text("Defining phases helps build client trust.",
                          style: TextStyleHelper.instance.body12Medium.copyWith(
                              color: appTheme.gray_400,
                              fontStyle: FontStyle.italic)),
                    ),
                  ...suggestedMilestones.asMap().entries.map((entry) =>
                      Container(
                        margin: EdgeInsets.only(top: 12.h),
                        padding: EdgeInsets.all(16.h),
                        decoration: BoxDecoration(
                            color: appTheme.gray_50,
                            borderRadius: BorderRadius.circular(16.h),
                            border: Border.all(color: appTheme.gray_100)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.value['title'],
                                      style:
                                          TextStyleHelper.instance.body14Bold),
                                  Text("Allocated: ₹${entry.value['amount']}",
                                      style: TextStyleHelper.instance.body12Bold
                                          .copyWith(
                                              color: appTheme.indigo_A700)),
                                ],
                              ),
                            ),
                            IconButton(
                                onPressed: () => setModalState(() {
                                      suggestedMilestones.removeAt(entry.key);
                                      calculateTotal();
                                    }),
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors.red.shade400)),
                          ],
                        ),
                      )),
                  SizedBox(height: 40.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (amountController.text.isNotEmpty) {
                          await context.read<JobProvider>().submitBid(
                                jobId: projectPost.id,
                                userId: userId,
                                workerName: userName,
                                bidAmount:
                                    double.tryParse(amountController.text) ?? 0,
                                proposal: proposalController.text,
                                deliveryTime: timelineController.text,
                                suggestedMilestones: suggestedMilestones,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Proposal sent successfully!")));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.indigo_A700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.h)),
                          elevation: 2),
                      child: Text("Send Proposal",
                          style: TextStyleHelper.instance.body16Bold
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBidField(TextEditingController controller, String label,
      String hint, IconData icon,
      {int maxLines = 1, bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyleHelper.instance.body12Bold
                .copyWith(color: appTheme.gray_900)),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly,
          style: TextStyleHelper.instance.body14Medium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyleHelper.instance.body14Medium
                .copyWith(color: appTheme.gray_400),
            prefixIcon: Icon(icon, color: appTheme.indigo_A700, size: 20.h),
            fillColor: isReadOnly ? appTheme.gray_100 : appTheme.white_A700_01,
            filled: true,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.h),
                borderSide: BorderSide(color: appTheme.gray_200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.h),
                borderSide:
                    BorderSide(color: appTheme.indigo_A700, width: 1.5)),
          ),
        ),
      ],
    );
  }

  void _showAddMilestoneDialog(
      BuildContext context, Function(Map<String, dynamic>) onAdd) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.white_A700_01,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
        title: Text("Define Project Phase",
            style: TextStyleHelper.instance.body16Bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                style: TextStyleHelper.instance.body14Medium,
                decoration: const InputDecoration(
                    labelText: "Phase Title",
                    hintText: "e.g. Prototype Design")),
            SizedBox(height: 20.h),
            TextField(
                controller: amountController,
                style: TextStyleHelper.instance.body14Medium,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Milestone Value (₹)", hintText: "5000")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("Cancel", style: TextStyle(color: appTheme.gray_500))),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                onAdd({
                  'title': titleController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'description': 'Project Milestone',
                  'deadline': DateTime.now()
                      .add(const Duration(days: 7))
                      .millisecondsSinceEpoch
                });
                Navigator.pop(context);
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: appTheme.indigo_A700),
            child: const Text("Add Phase"),
          ),
        ],
      ),
    );
  }
}

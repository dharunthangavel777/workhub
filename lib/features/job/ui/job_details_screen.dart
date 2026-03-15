import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qwok/core/config/app_export.dart';
import 'package:qwok/core/services/toast_service.dart';
import 'package:qwok/features/job/domain/models/job.dart';
import 'package:qwok/features/job/logic/job_controller.dart';
import 'package:qwok/features/auth/logic/auth_controller.dart';
import 'package:qwok/features/freelance/ui/project_dashboard_screen.dart';
import 'package:qwok/core/shared_widgets/smart_button.dart';
import 'package:qwok/core/orchestration/enterprise_state.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:qwok/core/analytics/behavioral_tracker.dart';
import 'package:qwok/features/profile/ui/edit_profile_screen.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job post;

  const JobDetailsScreen({super.key, required this.post});

  bool get isJob => post.postType == 'job';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: appTheme.indigoA700)),
      );
    }

    final isFreelancer = user.activeMode == 'freelancer';
    final title = post.title;
    final companyName =
        post.companyName ?? (isJob ? "N/A" : "Freelance Project");
    final logoUrl = post.companyLogo;
    final ownerName = post.ownerName ?? "Hiring Manager";

    return VisibilityDetector(
      key: Key('job_details_${post.id}'),
      onVisibilityChanged: (visibilityInfo) {
        final visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage > 50) {
          BehavioralTracker().onDwellStart(post.id, post.postType);
        } else {
          BehavioralTracker().onDwellEnd(post.id);
        }
      },
      child: Scaffold(
        backgroundColor: CustomColors.lightBg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          cacheExtent: 1000,
          slivers: [
            _buildAppBar(context, logoUrl, companyName),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 30.h),
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
                            color: appTheme.indigoA700,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.verified, color: Colors.blue, size: 16.h),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    // Professional Highlight Grid
                    RepaintBoundary(child: _buildSpecificationGrid()),

                    SizedBox(height: 40.h),

                    // Description & Roles
                    RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            isJob ? _buildJobContent() : _buildProjectContent(),
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Skills Section with professional chips
                    RepaintBoundary(child: _buildSkillsSection()),

                    SizedBox(height: 40.h),

                    // Recruiter Info Card
                    RepaintBoundary(
                        child: _buildPostedBySection(ownerName, companyName)),

                    SizedBox(height: 120.h), // Safe area for bottom navigation
                  ],
                ),
              ),
            ),
          ],
        ), // CustomScrollView ends here
        bottomNavigationBar: (user.uid == post.ownerId)
            ? null
            : _buildBottomBar(context, user, isFreelancer),
      ), // Scaffold ends here
    ); // VisibilityDetector ends here
  }

  Widget _buildAppBar(
      BuildContext context, String? logoUrl, String companyName) {
    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leadingWidth: 70.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: appTheme.gray900, size: 18.h),
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
                    appTheme.indigoA700,
                    appTheme.indigoA700.withValues(alpha: 0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 16.w,
              child: Hero(
                tag: 'logo-${post.id}',
                child: Container(
                  height: 80.h,
                  width: 80.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.h),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                    border: Border.all(color: appTheme.gray100, width: 1),
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
                                color: appTheme.indigoA700,
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
        color: appTheme.whiteA70001,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: appTheme.gray100),
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
                          ? "${post.experienceMin}-${post.experienceMax} yrs"
                          : post.experienceLevel ?? "No data")),
              _buildVerticalDivider(),
              Expanded(
                  child: _buildSpecItem(
                      Icons.payments_outlined,
                      "Salary/Budget",
                      isJob
                          ? "₹${post.budgetMin}-${post.budgetMax} / ${post.compensationType}"
                          : "₹${post.budgetMin}-${post.budgetMax}")),
            ],
          ),
          Divider(height: 32.h, color: appTheme.gray200),
          Row(
            children: [
              Expanded(
                  child: _buildSpecItem(
                      Icons.location_on_outlined, "Location", post.location)),
              _buildVerticalDivider(),
              Expanded(
                  child: _buildSpecItem(Icons.calendar_month_outlined,
                      "Deadline", _getDeadlineText())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() =>
      Container(height: 40.h, width: 1, color: appTheme.gray200);

  String _getDeadlineText() {
    final deadline = post.deadline;
    if (deadline == null) return "No Deadline";
    return "${deadline.day}/${deadline.month}/${deadline.year}";
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: appTheme.gray400, size: 16.h),
            SizedBox(width: 6.w),
            Text(label,
                style: TextStyleHelper.instance.body10Medium
                    .copyWith(color: appTheme.gray500)),
          ],
        ),
        SizedBox(height: 6.h),
        Text(value,
            style: TextStyleHelper.instance.body14Bold
                .copyWith(color: appTheme.gray900)),
      ],
    );
  }

  Widget _buildContentSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyleHelper.instance.body16Bold),
        SizedBox(height: 12.h),
        Text(
          content,
          style: TextStyleHelper.instance.body14Regular.copyWith(
            color: appTheme.gray700,
            height: 1.6,
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
            color: appTheme.whiteA70001,
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(color: appTheme.gray100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24.h,
                backgroundColor: appTheme.gray50,
                child: Icon(Icons.person_pin,
                    color: appTheme.indigoA700, size: 28.h),
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
                        if (post.isVerified) ...[
                          SizedBox(width: 4.w),
                          Icon(Icons.verified, color: Colors.blue, size: 14.h),
                        ],
                      ],
                    ),
                    Text(isJob ? companyName : "Hiring Manager",
                        style: TextStyleHelper.instance.body12Medium
                            .copyWith(color: appTheme.gray500)),
                    if (isJob) ...[
                      SizedBox(height: 4.h),
                      Text(
                        "${post.companyIndustry ?? 'N/A'} • ${post.companySize ?? 'N/A'}",
                        style: TextStyleHelper.instance.body10Medium
                            .copyWith(color: appTheme.gray400),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                    color: appTheme.gray50,
                    borderRadius: BorderRadius.circular(12.h)),
                child: Text("Contact",
                    style: TextStyleHelper.instance.body12Bold
                        .copyWith(color: appTheme.indigoA700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final List<String> skills = post.requiredSkills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Key Competencies", style: TextStyleHelper.instance.body16Bold),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: skills.map((s) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: appTheme.indigoA700.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.h),
                border: Border.all(
                    color: appTheme.indigoA700.withValues(alpha: 0.1)),
              ),
              child: Text(
                s,
                style: TextStyleHelper.instance.body12Bold
                    .copyWith(color: appTheme.indigoA700),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildJobContent() {
    return [
      _buildContentSection("Role Overview", post.description),
      SizedBox(height: 32.h),
      _buildContentSection("Key Responsibilities", post.responsibilities),
      if (post.preferredSkills != null && post.preferredSkills!.isNotEmpty) ...[
        SizedBox(height: 32.h),
        _buildContentSection(
            "Preferred Qualifications", post.preferredSkills!.join('\n• ')),
      ],
      SizedBox(height: 32.h),
      Text("Administrative Details",
          style: TextStyleHelper.instance.body16Bold),
      SizedBox(height: 16.h),
      _buildDetailRow("Contract Type", post.type),
      _buildDetailRow("Working Shift", post.shiftType ?? "Standard"),
      _buildDetailRow("Vacancies", "${post.openings}"),
      _buildDetailRow(
          "Educational Criteria", post.education ?? "Not Specified"),
      if (post.maxApplications != null)
        _buildDetailRow("Application Limit", "${post.maxApplications}"),
      _buildDetailRow("Applications", "${post.applicationsCount}"),
    ];
  }

  List<Widget> _buildProjectContent() {
    return [
      _buildContentSection("Project Objectives", post.description),
      SizedBox(height: 32.h),
      if (post.deliverables != null && post.deliverables!.isNotEmpty) ...[
        _buildContentSection(
            "Key Deliverables", post.deliverables!.join('\n• ')),
        SizedBox(height: 32.h),
      ],
      Text("Operational Framework", style: TextStyleHelper.instance.body16Bold),
      SizedBox(height: 16.h),
      _buildDetailRow(
          "Estimated Duration", post.projectDuration ?? "Not Specified"),
      _buildDetailRow("Collaboration Type", post.type),
      if (post.depositAmount != null)
        _buildDetailRow("Initial Deposit", "₹${post.depositAmount}"),
      _buildDetailRow(
          "Confidentiality (NDA)", post.ndaRequired ? "Mandatory" : "Optional"),
      if (post.maxApplications != null)
        _buildDetailRow("Proposal Limit", "${post.maxApplications}"),
      _buildDetailRow("Proposals", "${post.applicationsCount}"),
      if (post.termsAndConditions != null) ...[
        SizedBox(height: 16.h),
        _buildContentSection("Terms & Conditions", post.termsAndConditions!),
      ],
    ];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray500)),
          Text(value,
              style: TextStyleHelper.instance.body14Bold
                  .copyWith(color: appTheme.gray900)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, dynamic user, bool isFreelancer) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, _) {
        final application = post.applicants?[user.uid];
        final String? status = application?['status'];
        final bool isApproved = status?.toLowerCase() == 'approved';
        final bool hasApplied = application != null ||
            jobProvider.appliedJobIds.contains(post.id) ||
            jobProvider.appliedProjectIds.contains(post.id);

        return Container(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          decoration: BoxDecoration(
            color: appTheme.whiteA70001,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -10))
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56.h,
            child: isApproved
                ? _buildDashboardButton(context)
                : _buildActionButton(context, user, isFreelancer,
                    hasApplied: hasApplied),
          ),
        );
      },
    );
  }

  Widget _buildDashboardButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        final jobProvider = context.read<JobProvider>();
        final project =
            jobProvider.projects.where((p) => p.jobId == post.id).firstOrNull;
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
      BuildContext context, dynamic user, bool isFreelancer,
      {bool hasApplied = false}) {
    final bool isClosed = _isPostClosed();
    final bool isProject = post.postType == 'project';

    String buttonText;
    if (isClosed) {
      buttonText = isProject ? "Proposals Closed" : "Applications Closed";
    } else if (hasApplied) {
      buttonText = isProject ? "Proposal Sent" : "Application Sent";
    } else if (isFreelancer || isProject) {
      buttonText = "Place a Bid";
    } else {
      buttonText = "Submit Application";
    }

    return SmartButton(
      text: (isClosed || hasApplied) ? buttonText : "Apply",
      icon: (isClosed || hasApplied) 
          ? null 
          : Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20.h),
      onPressed: (isClosed || hasApplied)
          ? null
          : () => _handleApplyAction(context, user, isFreelancer),
      state: SmartButtonState.idle,
    );
  }

  bool _isPostClosed() {
    final deadline = post.deadline;
    final maxApps = post.maxApplications;
    final currentApps = post.applicants?.length ?? 0;
    if (deadline != null && DateTime.now().isAfter(deadline)) return true;
    if (maxApps != null && currentApps >= maxApps) return true;
    return false;
  }

  void _handleApplyAction(
      BuildContext context, dynamic user, bool isFreelancer) {
    if (user.profileCompletion < 80) {
      _showIncompleteProfileDialog(context, user);
      return;
    }
    if (isFreelancer) {
      _showBidForm(context, post, user.uid, user.displayName,
          user.jobCategory ?? "Professional", user.photoURL);
    } else {
      _showApplyConfirmation(context, post, user.uid, user.displayName,
          user.jobCategory ?? "Professional", user.photoURL);
    }
  }

  void _showIncompleteProfileDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.whiteA70001,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
        title:
            Text("Action Required", style: TextStyleHelper.instance.body18Bold),
        content: Text(
          "Your profile is only ${user.profileCompletion}% complete. A minimum of 80% is required to apply for opportunities.",
          style: TextStyleHelper.instance.body14Medium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Later", style: TextStyleHelper.instance.body14Bold),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.indigoA700,
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.h)),
            ),
            child: Text(
              "Complete Now",
              style: TextStyleHelper.instance.body14Bold.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyConfirmation(BuildContext context, Job post, String userId,
      String userName, String? userRole, String? userAvatar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.whiteA70001,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
        title: Text("Confirm Application",
            style: TextStyleHelper.instance.body18Bold),
        content: Text(
          "Are you sure you want to apply for ${post.title} at ${post.companyName}?",
          style: TextStyleHelper.instance.body14Medium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyleHelper.instance.body14Bold),
          ),
          Consumer<JobProvider>(
            builder: (context, jobProvider, child) {
              final buttonState = jobProvider.isLoading
                  ? SmartButtonState.loading
                  : SmartButtonState.idle;

              return SmartButton(
                text: "Confirm",
                state: buttonState,
                onPressed: () async {
                  try {
                    await jobProvider.apply(
                      post: post,
                      userId: userId,
                      workerName: userName,
                      workerRole: userRole,
                      workerAvatar: userAvatar,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ToastService().showSuccess("Application submitted!");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ToastService().showError("Submission failed", 
                        message: e.toString().replaceAll('Exception: ', ''));
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBidForm(BuildContext context, Job jobPost, String userId,
      String userName, String userRole, String? userAvatar) {
    final amountController = TextEditingController();
    final proposalController = TextEditingController();
    final durationValueController = TextEditingController();
    String durationUnit = 'Days';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final jobProvider = context.read<JobProvider>();

          // Load draft on first build
          Future<void> loadDraft() async {
            final draft = await jobProvider.getProposalDraft(jobPost.id);
            if (draft != null && amountController.text.isEmpty) {
              setModalState(() {
                amountController.text = draft['bidAmount']?.toString() ?? '';
                proposalController.text = draft['proposal'] ?? '';
                durationValueController.text = draft['deliveryValue'] ?? '';
                durationUnit = draft['deliveryUnit'] ?? 'Days';
              });
            }
          }

          loadDraft();

          void autoSave() {
            jobProvider.saveProposalDraft(jobPost.id, {
              'bidAmount': double.tryParse(amountController.text),
              'proposal': proposalController.text,
              'deliveryValue': durationValueController.text,
              'deliveryUnit': durationUnit,
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
                color: appTheme.whiteA70001,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32.h))),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w,
                MediaQuery.of(context).viewInsets.bottom + 24.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40.w,
                          height: 4.h,
                          margin: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                              color: appTheme.gray200,
                              borderRadius: BorderRadius.circular(2)))),
                  SizedBox(height: 16.h),
                  Text("Submit Proposal",
                      style: TextStyleHelper.instance.headline22Bold),
                  SizedBox(height: 8.h),
                  Text("Drafts are saved automatically as you type.",
                      style: TextStyleHelper.instance.body12Medium.copyWith(
                          color: appTheme.indigoA700.withValues(alpha: 0.7))),
                  SizedBox(height: 24.h),
                  _buildBidField(
                    amountController,
                    "Contract Amount (₹)",
                    "Your competitive quote",
                    Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => autoSave(),
                  ),
                  SizedBox(height: 20.h),
                  Text("Expected Delivery",
                      style: TextStyleHelper.instance.body12Bold
                          .copyWith(color: appTheme.gray900)),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationValueController,
                          onChanged: (_) => autoSave(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Value",
                            fillColor: appTheme.gray50,
                            filled: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.h),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.h),
                          color: appTheme.gray50,
                        ),
                        child: DropdownButton<String>(
                          value: durationUnit,
                          underline: const SizedBox(),
                          items: ['Days', 'Weeks', 'Months']
                              .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u,
                                      style: TextStyleHelper
                                          .instance.body14Medium)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => durationUnit = val);
                              autoSave();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Text("Proposal Details",
                      style: TextStyleHelper.instance.body12Bold),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: proposalController,
                    onChanged: (_) => autoSave(),
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText:
                          "Describe why you are the best fit for this project...",
                      fillColor: appTheme.gray50,
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.h),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Consumer<JobProvider>(
                    builder: (context, jp, _) {
                      return SmartButton(
                        text: "Submit Proposal",
                        state: jp.state.status == UnifiedState.loading
                            ? SmartButtonState.loading
                            : SmartButtonState.idle,
                        onPressed: () async {
                          final bidAmount =
                              double.tryParse(amountController.text) ?? 0;
                          final minBudget = jobPost.budgetMin ?? 0;
                          final maxBudget = jobPost.budgetMax ?? 999999999;

                          if (amountController.text.isEmpty ||
                              proposalController.text.isEmpty) {
                            ToastService().showWarning("Incomplete Fields", message: "Please fill in all required fields");
                            return;
                          }

                          if (bidAmount < minBudget || bidAmount > maxBudget) {
                            ToastService().showWarning("Invalid Bid", message: "Bid must be between ₹$minBudget and ₹$maxBudget");
                            return;
                          }

                          try {
                            await jp.submitBid(
                              jobPost: jobPost,
                              userId: userId,
                              workerName: userName,
                              workerRole: userRole,
                              workerAvatar: userAvatar,
                              bidAmount: double.parse(amountController.text),
                              proposal: proposalController.text,
                              deliveryTime:
                                  "${durationValueController.text} $durationUnit",
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ToastService().showSuccess("Success", message: "Proposal submitted successfully!");
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ToastService().showError("Error", message: e.toString().replaceAll('Exception: ', ''));
                            }
                          }
                        },
                      );
                    },
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
      {int maxLines = 1,
      bool isReadOnly = false,
      TextInputType? keyboardType,
      void Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyleHelper.instance.body12Bold
                .copyWith(color: appTheme.gray900)),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly,
          keyboardType: keyboardType,
          onChanged: onChanged,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
              : null,
          style: TextStyleHelper.instance.body14Medium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyleHelper.instance.body14Medium
                .copyWith(color: appTheme.gray400),
            prefixIcon: Icon(icon, color: appTheme.indigoA700, size: 20.h),
            fillColor: isReadOnly ? appTheme.gray100 : appTheme.whiteA70001,
            filled: true,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.h),
                borderSide: BorderSide(color: appTheme.gray200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.h),
                borderSide:
                    BorderSide(color: appTheme.indigoA700, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

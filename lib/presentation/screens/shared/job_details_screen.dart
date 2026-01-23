import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:work_hub/utils/image_constant.dart';
import '../../../config/app_export.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import 'package:work_hub/theme/theme_helper.dart';
import 'package:work_hub/utils/size_utils.dart';
import 'package:work_hub/data/models/job_post_model.dart';
import 'package:work_hub/data/models/project_post_model.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/utils/skill_icon_utils.dart';
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
      bottomNavigationBar:
          (user.uid == (isJob ? jobPost.ownerId : projectPost.ownerId))
              ? null
              : _buildBottomBar(context, user, isFreelancer),
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
    final durationValueController = TextEditingController();
    final projectPost = post as ProjectPostModel;
    String durationUnit = 'Days';
    PlatformFile? proposalDocument;
    bool isUploadingDocument = false;
    bool isBold = false;
    bool isItalic = false;
    bool isUnderline = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickDocument() async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
              );
              if (result != null) {
                setModalState(() {
                  proposalDocument = result.files.first;
                });
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error picking file: $e')),
              );
            }
          }

          Future<String?> uploadDocument() async {
            if (proposalDocument == null) return null;
            try {
              setModalState(() => isUploadingDocument = true);
              final file = File(proposalDocument!.path!);
              final fileName =
                  'proposals/${userId}_${DateTime.now().millisecondsSinceEpoch}_${proposalDocument!.name}';
              final ref = FirebaseStorage.instance.ref().child(fileName);
              await ref.putFile(file);
              final url = await ref.getDownloadURL();
              setModalState(() => isUploadingDocument = false);
              return url;
            } catch (e) {
              setModalState(() => isUploadingDocument = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error uploading document: $e')),
              );
              return null;
            }
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
                      keyboardType: TextInputType.number),
                  SizedBox(height: 20.h),
                  // Duration field with dropdown
                  Text("Delivery Timeline",
                      style: TextStyleHelper.instance.body12Bold
                          .copyWith(color: appTheme.gray_900)),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: durationValueController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: TextStyleHelper.instance.body14Medium,
                          decoration: InputDecoration(
                            hintText: "e.g. 14",
                            hintStyle: TextStyleHelper.instance.body14Medium
                                .copyWith(color: appTheme.gray_400),
                            prefixIcon: Icon(Icons.timer_outlined,
                                color: appTheme.indigo_A700, size: 20.h),
                            fillColor: appTheme.white_A700_01,
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.h),
                                borderSide:
                                    BorderSide(color: appTheme.gray_200)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.h),
                                borderSide: BorderSide(
                                    color: appTheme.indigo_A700, width: 1.5)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: appTheme.white_A700_01,
                            borderRadius: BorderRadius.circular(14.h),
                            border: Border.all(color: appTheme.gray_200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: durationUnit,
                              isExpanded: true,
                              items: ['Days', 'Weeks', 'Months']
                                  .map((unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit,
                                            style: TextStyleHelper
                                                .instance.body14Medium),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  durationUnit = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Proposal document upload
                  Text("Proposal Document (Optional)",
                      style: TextStyleHelper.instance.body12Bold
                          .copyWith(color: appTheme.gray_900)),
                  SizedBox(height: 10.h),
                  InkWell(
                    onTap: pickDocument,
                    child: Container(
                      padding: EdgeInsets.all(16.h),
                      decoration: BoxDecoration(
                        color: appTheme.gray_50,
                        borderRadius: BorderRadius.circular(14.h),
                        border: Border.all(color: appTheme.gray_200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.upload_file,
                              color: appTheme.indigo_A700, size: 24.h),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              proposalDocument != null
                                  ? proposalDocument!.name
                                  : "Upload PDF, DOC, or TXT file",
                              style: TextStyleHelper.instance.body14Medium
                                  .copyWith(
                                      color: proposalDocument != null
                                          ? appTheme.gray_900
                                          : appTheme.gray_400),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (proposalDocument != null)
                            IconButton(
                              icon: Icon(Icons.close, size: 20.h),
                              onPressed: () {
                                setModalState(() {
                                  proposalDocument = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Proposal description with formatting toolbar
                  Text("Proposal Description",
                      style: TextStyleHelper.instance.body12Bold
                          .copyWith(color: appTheme.gray_900)),
                  SizedBox(height: 10.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.h),
                      border: Border.all(color: appTheme.gray_200),
                    ),
                    child: Column(
                      children: [
                        // Formatting toolbar
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: appTheme.gray_50,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(14.h),
                              topRight: Radius.circular(14.h),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text("WRITE",
                                  style: TextStyleHelper.instance.body12Bold
                                      .copyWith(color: appTheme.gray_600)),
                              SizedBox(width: 16.w),
                              IconButton(
                                icon: Icon(Icons.format_bold,
                                    size: 20.h,
                                    color: isBold
                                        ? appTheme.indigo_A700
                                        : appTheme.gray_600),
                                onPressed: () {
                                  setModalState(() => isBold = !isBold);
                                },
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: Icon(Icons.format_italic,
                                    size: 20.h,
                                    color: isItalic
                                        ? appTheme.indigo_A700
                                        : appTheme.gray_600),
                                onPressed: () {
                                  setModalState(() => isItalic = !isItalic);
                                },
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: Icon(Icons.format_list_bulleted,
                                    size: 20.h, color: appTheme.gray_600),
                                onPressed: () {
                                  // Insert bullet point
                                  final text = proposalController.text;
                                  final selection =
                                      proposalController.selection;
                                  final newText =
                                      text.substring(0, selection.start) +
                                          '\n- ' +
                                          text.substring(selection.end);
                                  proposalController.text = newText;
                                  proposalController.selection =
                                      TextSelection.collapsed(
                                          offset: selection.start + 3);
                                },
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        // Text editor
                        TextField(
                          controller: proposalController,
                          maxLines: 8,
                          style: TextStyleHelper.instance.body14Medium.copyWith(
                            fontWeight:
                                isBold ? FontWeight.bold : FontWeight.normal,
                            fontStyle:
                                isItalic ? FontStyle.italic : FontStyle.normal,
                            decoration: isUnderline
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                "Describe your relevant experience and approach...",
                            hintStyle: TextStyleHelper.instance.body14Medium
                                .copyWith(color: appTheme.gray_400),
                            fillColor: appTheme.white_A700_01,
                            filled: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16.h),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: isUploadingDocument
                          ? null
                          : () async {
                              // Validate amount
                              final amount =
                                  double.tryParse(amountController.text);
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Please enter a valid amount")),
                                );
                                return;
                              }

                              // Validate duration
                              final durationValue =
                                  int.tryParse(durationValueController.text);
                              if (durationValue == null || durationValue <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Please enter a valid duration")),
                                );
                                return;
                              }

                              // Upload document if selected
                              if (proposalDocument != null) {
                                await uploadDocument();
                              }

                              final deliveryTime =
                                  "$durationValue $durationUnit";

                              await context.read<JobProvider>().submitBid(
                                jobId: projectPost.id,
                                userId: userId,
                                workerName: userName,
                                bidAmount: amount,
                                proposal: proposalController.text,
                                deliveryTime: deliveryTime,
                                suggestedMilestones: [],
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Proposal sent successfully!")));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.indigo_A700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.h)),
                          elevation: 2),
                      child: isUploadingDocument
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Send Proposal",
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
      {int maxLines = 1,
      bool isReadOnly = false,
      TextInputType? keyboardType}) {
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
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
              : null,
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
}

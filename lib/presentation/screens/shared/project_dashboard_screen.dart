import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'package:work_hub/theme/custom_colors.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import 'package:work_hub/theme/theme_helper.dart';
import 'package:work_hub/utils/size_utils.dart';
import 'package:work_hub/data/models/project_model.dart';
import 'package:work_hub/data/models/contract_terms_model.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/logic/providers/chat_provider.dart';
import '../chat/chat_room_screen.dart';
import 'package:work_hub/data/models/milestone_model.dart';
import 'contract_details_screen.dart';
import 'milestone_list_screen.dart';
import 'milestone_list_section_widget.dart';
import '../owner/escrow_deposit_screen.dart';
import 'package:work_hub/data/models/rating_model.dart';
import 'package:work_hub/data/models/time_entry_model.dart';
import '../../widgets/project_setup_stepper.dart';

class ProjectDashboardScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDashboardScreen({super.key, required this.project});

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  ProjectModel get project => widget.project;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final jobProvider = context.read<JobProvider>();
      jobProvider.listenToMilestones(project.id);
      jobProvider.fetchContractByProjectId(project.id);
      jobProvider.syncProjectProgress(project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final currentUser = context.watch<AuthProvider>().userModel;
    final project = jobProvider.projects.firstWhere(
      (p) => p.id == widget.project.id,
      orElse: () => widget.project,
    );
    final isWorker = currentUser?.uid == project.workerId;
    final isOwner = currentUser?.uid == project.ownerId;
    final contract = jobProvider.currentContract;

    final needsSign = contract != null &&
        contract.projectId == project.id &&
        ((isWorker && !contract.workerAccepted) ||
            (isOwner && !contract.ownerAccepted));

    return Scaffold(
      backgroundColor: appTheme.white_A700_01,
      appBar: AppBar(
        backgroundColor: appTheme.white_A700_01,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appTheme.gray_900),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(FontAwesomeIcons.circleQuestion,
                color: appTheme.gray_400, size: 20.h),
            onPressed: () {},
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (needsSign) _buildSigningBanner(context, contract),
            if (project.status == 'setup')
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.h),
                    child: ProjectSetupStepper(project: project),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      _buildHeader(),
                      SizedBox(height: 24.h),
                      _buildProjectOverview(),
                      if (project.contractId != null) ...[
                        SizedBox(height: 16.h),
                        _buildContractCard(context),
                      ],
                      SizedBox(height: 32.h),
                      _buildSectionTitle("Project Progress"),
                      SizedBox(height: 16.h),
                      _ProgressSection(project: project),
                      SizedBox(height: 32.h),
                      SizedBox(height: 32.h),
                      _buildSectionTitle(
                        "Milestone Timeline",
                        actionText: "Manage",
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MilestoneListScreen(project: project),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      MilestoneListSection(project: project),
                      SizedBox(height: 32.h),
                      _buildSectionTitle("Shared Assets"),
                      SizedBox(height: 16.h),
                      _FileSharingSection(project: project),
                      SizedBox(height: 32.h),
                      if (project.projectType == 'hourly') ...[
                        _buildSectionTitle("Time Tracking"),
                        SizedBox(height: 16.h),
                        _TimeTrackingSection(project: project),
                        SizedBox(height: 32.h),
                      ],
                      _PaymentSection(project: project),
                      SizedBox(height: 32.h),
                      _RatingSection(project: project),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: project.status == 'setup'
          ? null
          : _buildBottomActions(context, isWorker, isOwner),
    );
  }

  Widget _buildSigningBanner(BuildContext context, ContractTerms contract) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border:
            Border(bottom: BorderSide(color: Colors.orange.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "Signature Required: Please sign the contract to proceed.",
              style: TextStyleHelper.instance.body12Bold
                  .copyWith(color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ContractDetailsScreen(contractId: contract.id),
                ),
              );
            },
            child: Text(
              "SIGN NOW",
              style: TextStyleHelper.instance.body12Bold
                  .copyWith(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title,
      {VoidCallback? onAction, String? actionText}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyleHelper.instance.body18Bold
              .copyWith(color: appTheme.gray_900),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: appTheme.gray_100)),
        if (onAction != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                actionText ?? "View All",
                style: TextStyleHelper.instance.body14Bold
                    .copyWith(color: appTheme.indigo_A700),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: appTheme.indigo_A700.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Text(
            project.status.toUpperCase(),
            style: TextStyleHelper.instance.body10Bold.copyWith(
              color: appTheme.indigo_A700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          project.title,
          style: TextStyleHelper.instance.headline30Bold.copyWith(
            color: appTheme.gray_900,
            fontSize: 26.fSize,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          project.description,
          style: TextStyleHelper.instance.body14Medium.copyWith(
            color: appTheme.gray_600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectOverview() {
    final startDate = DateTime.fromMillisecondsSinceEpoch(project.createdAt);
    final deadline = project.deadline != null
        ? DateTime.fromMillisecondsSinceEpoch(project.deadline!)
        : null;

    return Container(
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
              "Started", intl.DateFormat('dd MMM').format(startDate)),
          _buildVerticalDivider(),
          if (deadline != null) ...[
            _buildInfoItem(
                "Deadline", intl.DateFormat('dd MMM').format(deadline)),
            _buildVerticalDivider(),
          ],
          _buildInfoItem(
            "Budget",
            "₹${(project.budget ?? 0).toStringAsFixed(0)}",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyleHelper.instance.body12Medium
              .copyWith(color: appTheme.gray_500),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyleHelper.instance.body16Bold
              .copyWith(color: appTheme.gray_900),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30.h, width: 1, color: appTheme.gray_200);
  }

  Widget _buildBottomActions(
      BuildContext context, bool isWorker, bool isOwner) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        border: Border(top: BorderSide(color: appTheme.gray_100)),
      ),
      child: _ActionButtons(project: project),
    );
  }

  Widget _buildContractCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (project.contractId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ContractDetailsScreen(contractId: project.contractId!),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(20.h),
        decoration: BoxDecoration(
          color: appTheme.white_A700_01,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: appTheme.indigo_A700.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: appTheme.indigo_A700.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Icon(Icons.description,
                  color: appTheme.indigo_A700, size: 24.h),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Contract Agreement",
                      style: TextStyleHelper.instance.body16Bold),
                  SizedBox(height: 4.h),
                  Text("Tap to view contract details",
                      style: TextStyleHelper.instance.body12Medium
                          .copyWith(color: appTheme.gray_500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: appTheme.gray_400, size: 16.h),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final ProjectModel project;
  const _ProgressSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final milestones = context.watch<JobProvider>().milestones;
    double progress = 0;

    if (milestones.isNotEmpty) {
      final approvedCount =
          milestones.where((m) => m.status == MilestoneStatus.approved).length;
      progress = approvedCount / milestones.length;
    } else {
      progress = project.progress;
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Completion Rate",
                  style: TextStyleHelper.instance.body14Medium
                      .copyWith(color: appTheme.gray_600)),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyleHelper.instance.body18Bold
                    .copyWith(color: appTheme.indigo_A700),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Stack(
            children: [
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: appTheme.gray_200,
                    borderRadius: BorderRadius.circular(10.h)),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [appTheme.indigo_A700, Colors.blueAccent]),
                    borderRadius: BorderRadius.circular(10.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ProjectModel project;
  const _ActionButtons({required this.project});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton.icon(
        onPressed: () async {
          final authProvider = context.read<AuthProvider>();
          final chatProvider = context.read<ChatProvider>();
          final currentUser = authProvider.userModel;

          if (currentUser != null) {
            final isWorker = currentUser.uid == project.workerId;
            final otherId = isWorker ? project.ownerId : project.workerId;
            final otherName =
                isWorker ? "Project Owner" : (project.workerName ?? "Worker");

            final chatId =
                await chatProvider.startChat(currentUser.uid, otherId);

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatRoomScreen(chatId: chatId, otherUserName: otherName),
                ),
              );
            }
          }
        },
        icon: Icon(FontAwesomeIcons.commentDots, size: 18.h),
        label: Text("Collaboration Center",
            style: TextStyleHelper.instance.body16Bold
                .copyWith(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: appTheme.indigo_A700,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
          elevation: 2,
        ),
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  final ProjectModel project;
  const _PaymentSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final payments = project.payments ?? {};
    double totalPaid = 0;
    payments.forEach((key, value) {
      if (value is Map && value['status'] == 'released') {
        totalPaid += (value['amount'] as num).toDouble();
      }
    });

    final currentUser = context.read<AuthProvider>().userModel;
    final isOwner = currentUser?.uid == project.ownerId;

    return Container(
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Financial Ledger", style: TextStyleHelper.instance.body18Bold),
          SizedBox(height: 20.h),
          _buildLedgerRow(
              "Gross Total Released", "₹${totalPaid.toStringAsFixed(2)}"),
          _buildLedgerRow(
            "Escrow Balance (Funds Held)",
            "₹${project.escrowBalance.toStringAsFixed(2)}",
            isHighlight: project.escrowBalance > 0,
          ),
          _buildLedgerRow(
              "Platform Fees", "₹${project.platformFee.toStringAsFixed(2)}"),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Divider(color: appTheme.gray_200)),
          _buildLedgerRow(
            "Net Distributed",
            "₹${project.netEarnings.toStringAsFixed(2)}",
            isHighlight: true,
          ),
          if (isOwner) ...[
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EscrowDepositScreen(project: project)),
                ),
                icon: const Icon(Icons.add_card, size: 18),
                label: const Text("Deposit Funds"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: appTheme.indigo_A700,
                  side: BorderSide(color: appTheme.indigo_A700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.h)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLedgerRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray_500)),
          Text(
            value,
            style: isHighlight
                ? TextStyleHelper.instance.body16Bold
                    .copyWith(color: appTheme.indigo_A700)
                : TextStyleHelper.instance.body14Bold
                    .copyWith(color: appTheme.gray_900),
          ),
        ],
      ),
    );
  }
}

class _FileSharingSection extends StatelessWidget {
  final ProjectModel project;
  const _FileSharingSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final sharedFiles = project.sharedFiles ?? [];
    final currentUser = context.read<AuthProvider>().userModel;

    return Column(
      children: [
        if (sharedFiles.isEmpty)
          Container(
            padding: EdgeInsets.all(32.h),
            width: double.infinity,
            decoration: BoxDecoration(
                color: appTheme.gray_50,
                borderRadius: BorderRadius.circular(24.h)),
            child: Column(
              children: [
                Icon(FontAwesomeIcons.folderOpen,
                    color: appTheme.gray_300, size: 40.h),
                SizedBox(height: 16.h),
                Text("No shared assets yet",
                    style: TextStyleHelper.instance.body14Medium
                        .copyWith(color: appTheme.gray_500)),
              ],
            ),
          )
        else
          ...sharedFiles
              .map((file) => _buildFileCard(context, file, currentUser)),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: OutlinedButton.icon(
            onPressed: () => _uploadFile(context),
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Documents"),
            style: OutlinedButton.styleFrom(
              foregroundColor: appTheme.indigo_A700,
              side: BorderSide(color: appTheme.indigo_A700.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.h)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(
      BuildContext context, dynamic file, dynamic currentUser) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Row(
        children: [
          _getFileIcon(file['name'] ?? ''),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file['name'] ?? 'Unknown',
                    style: TextStyleHelper.instance.body14Bold),
                Text(
                    "${_formatBytes(file['size'] ?? 0)} • ${file['uploadedByName'] ?? 'User'}",
                    style: TextStyleHelper.instance.body12Medium
                        .copyWith(color: appTheme.gray_500)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download, color: appTheme.indigo_A700, size: 20.h),
            onPressed: () => _launchUrl(file['url']),
          ),
        ],
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    IconData icon = FontAwesomeIcons.fileLines;
    Color color = appTheme.indigo_A700;

    if (ext == 'pdf') {
      icon = FontAwesomeIcons.filePdf;
      color = Colors.redAccent;
    } else if (['doc', 'docx'].contains(ext)) {
      icon = FontAwesomeIcons.fileWord;
      color = Colors.blue;
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      icon = FontAwesomeIcons.fileImage;
      color = Colors.green;
    }

    return Icon(icon, color: color, size: 24.h);
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _uploadFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final currentUser = context.read<AuthProvider>().userModel;
      if (currentUser == null) return;

      await context.read<JobProvider>().uploadFile(
            projectId: project.id,
            file: file,
            fileName: result.files.single.name,
            userId: currentUser.uid,
            userName: currentUser.displayName,
          );
    } catch (e) {
      /* Error handling Snackbars */
    }
  }
}

class _RatingSection extends StatelessWidget {
  final ProjectModel project;
  const _RatingSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().userModel;
    if (currentUser == null) return const SizedBox.shrink();

    final isOwner = currentUser.uid == project.ownerId;
    final raterRole = isOwner ? 'owner' : 'worker';
    final hasCompleted =
        project.status == 'completed' || project.progress == 1.0;

    return FutureBuilder<Rating?>(
      future: context
          .read<JobProvider>()
          .getRatingByProjectAndRole(project.id, raterRole),
      builder: (context, snapshot) {
        final existingRating = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Performance Review",
                    style: TextStyleHelper.instance.body18Bold),
                SizedBox(width: 12.w),
                Expanded(child: Divider(color: appTheme.gray_100)),
              ],
            ),
            SizedBox(height: 16.h),
            if (existingRating != null)
              _buildRatingCard(existingRating)
            else if (hasCompleted)
              _buildSubmitRatingCard(context, currentUser, raterRole)
            else
              _buildReviewPendingCard(),
          ],
        );
      },
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Container(
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Your Feedback",
                  style: TextStyleHelper.instance.body12Bold
                      .copyWith(color: appTheme.gray_500)),
              _buildStarRating(rating.score),
            ],
          ),
          SizedBox(height: 12.h),
          Text(rating.review,
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildStarRating(double score) {
    return Row(
      children: List.generate(
          5,
          (index) => Icon(index < score ? Icons.star : Icons.star_border,
              color: Colors.amber, size: 16)),
    );
  }

  Widget _buildSubmitRatingCard(
      BuildContext context, dynamic currentUser, String raterRole) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: appTheme.indigo_A700.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: appTheme.indigo_A700.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(FontAwesomeIcons.starHalfStroke,
              color: appTheme.indigo_A700, size: 32.h),
          SizedBox(height: 16.h),
          Text("Project Finalized!",
              style: TextStyleHelper.instance.body18Bold),
          SizedBox(height: 8.h),
          Text("Share your experience to help the community grow.",
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.body12Medium
                  .copyWith(color: appTheme.gray_500)),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () {}, // Trigger rating dialog logic
              style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.indigo_A700,
                  foregroundColor: Colors.white),
              child: const Text("Submit Review"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPendingCard() {
    return Container(
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
          color: appTheme.gray_50, borderRadius: BorderRadius.circular(20.h)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: appTheme.gray_400, size: 20.h),
          SizedBox(width: 12.w),
          Text("Reviews open after project completion.",
              style: TextStyleHelper.instance.body12Medium
                  .copyWith(color: appTheme.gray_500)),
        ],
      ),
    );
  }
}

class _TimeTrackingSection extends StatelessWidget {
  final ProjectModel project;
  const _TimeTrackingSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().userModel;
    if (currentUser == null) return const SizedBox.shrink();
    final isWorker = currentUser.uid == project.workerId;
    final isOwner = currentUser.uid == project.ownerId;

    return StreamBuilder<List<TimeEntry>>(
      stream: context.read<JobProvider>().getTimeEntries(project.id),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];

        return Column(
          children: [
            if (entries.isEmpty)
              Container(
                padding: EdgeInsets.all(24.h),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: appTheme.gray_50,
                    borderRadius: BorderRadius.circular(24.h)),
                child: Column(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: appTheme.gray_300, size: 32.h),
                    SizedBox(height: 12.h),
                    Text("No time entries logged yet",
                        style: TextStyleHelper.instance.body14Medium
                            .copyWith(color: appTheme.gray_500)),
                  ],
                ),
              )
            else
              ...entries
                  .map((entry) => _buildTimeEntryCard(context, entry, isOwner)),
            SizedBox(height: 12.h),
            if (isWorker)
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: OutlinedButton.icon(
                  onPressed: () {}, // Show log time dialog
                  icon: const Icon(Icons.add_alarm_outlined),
                  label: const Text("Log Hours"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appTheme.indigo_A700,
                    side: BorderSide(
                        color: appTheme.indigo_A700.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.h)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTimeEntryCard(
      BuildContext context, TimeEntry entry, bool isOwner) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${entry.hours.toStringAsFixed(1)} Hours",
                  style: TextStyleHelper.instance.body16Bold),
              _buildStatusChip(entry.status),
            ],
          ),
          SizedBox(height: 8.h),
          Text(entry.description,
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray_600)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TimeEntryStatus status) {
    Color color = Colors.orange;
    if (status == TimeEntryStatus.approved) color = Colors.green;
    if (status == TimeEntryStatus.rejected) color = Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6.h)),
      child: Text(status.name.toUpperCase(),
          style: TextStyleHelper.instance.body10Bold.copyWith(color: color)),
    );
  }
}

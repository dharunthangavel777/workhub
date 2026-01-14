import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/custom_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/contract_terms_model.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/chat_provider.dart';
import '../chat/chat_room_screen.dart';
import '../../../data/models/milestone_model.dart';
import 'contract_details_screen.dart';
import 'milestone_list_screen.dart';
import '../owner/escrow_deposit_screen.dart';
import '../../../data/models/rating_model.dart';
import '../../../data/models/time_entry_model.dart';
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
      final jobProvider = context.read<JobProvider>();
      jobProvider.listenToMilestones(project.id);
      jobProvider.fetchContractByProjectId(project.id);
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
      backgroundColor: CustomColors.lightBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: CustomColors.darkText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.circleQuestion,
              color: CustomColors.textMuted,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: CustomColors.lightBg),
        child: SafeArea(
          child: Column(
            children: [
              if (needsSign) _buildSigningBanner(context, contract),
              if (project.status == 'setup')
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ProjectSetupStepper(project: project),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildProjectOverview(),
                        if (project.contractId != null) ...[
                          const SizedBox(height: 16),
                          _buildContractCard(context),
                        ],
                        _buildSectionTitle("Project Progress"),
                        const SizedBox(height: 16),
                        _ProgressSection(project: project),
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 32),
                        _buildSectionTitle("Shared Assets"),
                        const SizedBox(height: 16),
                        _FileSharingSection(project: project),
                        const SizedBox(height: 32),
                        if (project.projectType == 'hourly') ...[
                          _buildSectionTitle("Time Tracking"),
                          const SizedBox(height: 16),
                          _TimeTrackingSection(project: project),
                          const SizedBox(height: 32),
                        ],
                        _PaymentSection(project: project),
                        const SizedBox(height: 32),
                        _RatingSection(project: project),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.orange.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Signature Required: Please sign the contract to proceed.",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContractDetailsScreen(
                    contractId: contract.id,
                  ),
                ),
              );
            },
            child: const Text(
              "SIGN NOW",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.05))),
        if (onAction != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                actionText ?? "View All",
                style: const TextStyle(
                  color: CustomColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: CustomColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            project.status.toUpperCase(),
            style: const TextStyle(
              color: CustomColors.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          project.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          project.description,
          style: TextStyle(
            color: CustomColors.darkText,
            height: 1.5,
            fontSize: 15,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem("Started", "${startDate.day}/${startDate.month}"),
          _buildVerticalDivider(),
          if (deadline != null) ...[
            _buildInfoItem("Deadline", "${deadline.day}/${deadline.month}"),
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
          style: TextStyle(color: CustomColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: CustomColors.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.black.withValues(alpha: 0.1),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    bool isWorker,
    bool isOwner,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: CustomColors.lightBg,
        border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [Expanded(child: _ActionButtons(project: project))],
      ),
    );
  }

  Widget _buildContractCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (project.contractId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContractDetailsScreen(
                contractId: project.contractId!,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: CustomColors.primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CustomColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description,
                color: CustomColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contract Agreement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CustomColors.darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to view contract details',
                    style: TextStyle(
                      fontSize: 13,
                      color: CustomColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: CustomColors.textMuted,
              size: 16,
            ),
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
      progress = project
          .progress; // Fallback to manual progress if no milestones exist yet
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: CustomColors.primaryBlue.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Milestone Completion",
                style: TextStyle(
                  color: CustomColors.textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: CustomColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              color: CustomColors.primaryBlue,
              minHeight: 10,
            ),
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

            final chatId = await chatProvider.startChat(
              currentUser.uid,
              otherId,
            );

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomScreen(
                    chatId: chatId,
                    otherUserName: otherName,
                  ),
                ),
              );
            }
          }
        },
        icon: const Icon(FontAwesomeIcons.commentDots, size: 18),
        label: const Text("Collaboration Center"),
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
      if (value['status'] == 'released') {
        totalPaid += (value['amount'] as num).toDouble();
      }
    });

    final currentUser = context.read<AuthProvider>().userModel;
    final isOwner = currentUser?.uid == project.ownerId;

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            "Financial Ledger",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 20),
          _buildLedgerRow(
            "Gross Total Released",
            "₹${totalPaid.toStringAsFixed(2)}",
          ),
          _buildLedgerRow(
            "Escrow Balance (Funds Held)",
            "₹${project.escrowBalance.toStringAsFixed(2)}",
            isHighlight: project.escrowBalance > 0,
          ),
          _buildLedgerRow(
            "Platform Fees (Paid by Owner)",
            "₹${project.platformFee.toStringAsFixed(2)}",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.black12),
          ),
          _buildLedgerRow(
            "Net Distributed to Worker",
            "₹${project.netEarnings.toStringAsFixed(2)}",
            isHighlight: true,
          ),
          const SizedBox(height: 24),
          if (isOwner)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EscrowDepositScreen(project: project),
                      ),
                    ),
                    icon: const Icon(Icons.add_card, size: 20),
                    label: const Text("Deposit Funds"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CustomColors.primaryBlue,
                      side: const BorderSide(color: CustomColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              "Milestone History",
              style: TextStyle(
                color: CustomColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...payments.entries.where((e) => e.key != 'totalBudget').map((
              entry,
            ) {
              final amount = (entry.value['amount'] as num).toDouble();
              final date = DateTime.fromMillisecondsSinceEpoch(
                entry.value['releasedAt'] as int,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${date.day}/${date.month}/${date.year}",
                      style: const TextStyle(color: CustomColors.textMuted),
                    ),
                    Text(
                      "₹${amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: CustomColors.textMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 32),
          const Text(
            "Recent Activity",
            style: TextStyle(
              color: CustomColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (context.watch<JobProvider>().transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("No transactions recorded",
                  style:
                      TextStyle(color: CustomColors.textMuted, fontSize: 12)),
            )
          else
            ...context.watch<JobProvider>().transactions.map((tx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payment,
                          size: 16, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            tx.type.toString().split('.').last,
                            style: const TextStyle(
                                fontSize: 11, color: CustomColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${tx.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(
    String label,
    String value, {
    bool isNegative = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isHighlight ? CustomColors.darkText : CustomColors.textMuted,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isNegative
                  ? Colors.redAccent
                  : (isHighlight ? Colors.green : CustomColors.darkText),
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlight ? 16 : 14,
            ),
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
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: CustomColors.darkCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
            ),
            child: Column(
              children: [
                Icon(
                  FontAwesomeIcons.folderOpen,
                  color: CustomColors.textMuted.withValues(alpha: 0.3),
                  size: 40,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No files shared yet",
                  style: TextStyle(color: CustomColors.textMuted),
                ),
              ],
            ),
          )
        else
          ...sharedFiles.map(
            (file) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CustomColors.darkCard.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
              ),
              child: Row(
                children: [
                  _getFileIcon(file['name'] ?? ''),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file['name'] ?? 'Unknown File',
                          style: const TextStyle(
                            color: CustomColors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${_formatBytes(file['size'] ?? 0)} • ${file['uploadedByName'] ?? 'Unknown'}",
                          style: const TextStyle(
                            color: CustomColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          color: CustomColors.primaryBlue,
                          size: 20,
                        ),
                        onPressed: () => _launchUrl(file['url']),
                      ),
                      if (currentUser?.uid == file['uploadedBy'])
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _confirmDelete(context, file),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _uploadFile(context),
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Documents"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                  color: CustomColors.textMuted.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    IconData icon;
    Color color;

    switch (ext) {
      case 'pdf':
        icon = FontAwesomeIcons.filePdf;
        color = Colors.redAccent;
        break;
      case 'doc':
      case 'docx':
        icon = FontAwesomeIcons.fileWord;
        color = Colors.blue;
        break;
      case 'zip':
      case 'rar':
      case '7z':
        icon = FontAwesomeIcons.fileArchive;
        color = Colors.orange;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'svg':
        icon = FontAwesomeIcons.fileImage;
        color = Colors.green;
        break;
      default:
        icon = FontAwesomeIcons.fileLines;
        color = CustomColors.primaryBlue;
    }

    return Icon(icon, color: color, size: 24);
  }

  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes / 1024).floor();
    return ((bytes / (i * 1024)) * 1024).toStringAsFixed(decimals) +
        " " +
        suffixes[i];
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _uploadFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final currentUser = context.read<AuthProvider>().userModel;

      if (currentUser == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Uploading $fileName...")),
      );

      await context.read<JobProvider>().uploadFile(
            projectId: project.id,
            file: file,
            fileName: fileName,
            userId: currentUser.uid,
            userName: currentUser.displayName,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File uploaded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CustomColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete File?"),
        content: Text("Are you sure you want to delete '${file['name']}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<JobProvider>().deleteFile(
                      projectId: project.id,
                      fileMetadata: file,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("File deleted")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Delete failed: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
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
    final hasCompleted = project.status == 'completed';

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
                const Text(
                  "Performance Review",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CustomColors.darkText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        Divider(color: Colors.black.withValues(alpha: 0.05))),
              ],
            ),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Feedback",
                style: TextStyle(
                  color: CustomColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStarRating(rating.score),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rating.review,
            style: const TextStyle(
              color: CustomColors.darkText,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          if (rating.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: rating.tags.map((tag) => _buildTag(tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitRatingCard(
      BuildContext context, dynamic currentUser, String raterRole) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CustomColors.primaryBlue.withValues(alpha: 0.1),
            Colors.white
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: CustomColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            FontAwesomeIcons.starHalfStroke,
            color: CustomColors.primaryBlue,
            size: 32,
          ),
          const SizedBox(height: 16),
          const Text(
            "Project Finalized!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Share your experience to help the community grow.",
            textAlign: TextAlign.center,
            style: TextStyle(color: CustomColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  _showRatingDialog(context, currentUser, raterRole),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Submit Review"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPendingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: CustomColors.textMuted, size: 20),
          SizedBox(width: 12),
          Text(
            "Reviews open after project completion.",
            style: TextStyle(color: CustomColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double score) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < score ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CustomColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: CustomColors.primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRatingDialog(
      BuildContext context, dynamic currentUser, String raterRole) {
    final reviewController = TextEditingController();
    double currentScore = 5;
    final List<String> availableTags = [
      'Quality of Work',
      'Communication',
      'Timeliness',
      'Professionalism',
      'Technical Skills'
    ];
    final Set<String> selectedTags = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CustomColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Leave a Review",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      _getScoreLabel(currentScore),
                      style: const TextStyle(
                        color: CustomColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () =>
                              setModalState(() => currentScore = index + 1.0),
                          icon: Icon(
                            index < currentScore
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "What went well?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableTags.map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (val) {
                      setModalState(() {
                        if (val) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor:
                        CustomColors.primaryBlue.withValues(alpha: 0.2),
                    checkmarkColor: CustomColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? CustomColors.primaryBlue
                          : CustomColors.textMuted,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                "Detailed Comments",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewController,
                maxLines: 4,
                style: const TextStyle(color: CustomColors.darkText),
                decoration: InputDecoration(
                  hintText: "How was your experience working on this project?",
                  hintStyle: const TextStyle(color: CustomColors.textMuted),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (reviewController.text.isEmpty) return;

                    final ratedUserId = raterRole == 'owner'
                        ? project.workerId
                        : project.ownerId;

                    final rating = Rating(
                      id: '',
                      projectId: project.id,
                      ratedBy: currentUser.uid,
                      ratedUser: ratedUserId,
                      raterRole: raterRole,
                      score: currentScore,
                      review: reviewController.text,
                      tags: selectedTags.toList(),
                    );

                    await context.read<JobProvider>().submitRating(rating);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Submit Final Review",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 5) return "Exceptional!";
    if (score >= 4) return "Great Experience";
    if (score >= 3) return "Good / Average";
    if (score >= 2) return "Could be better";
    return "Poor Experience";
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
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CustomColors.darkCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.02)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: CustomColors.textMuted, size: 32),
                    SizedBox(height: 12),
                    Text(
                      "No time entries logged yet",
                      style: TextStyle(color: CustomColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              ...entries
                  .map((entry) => _buildTimeEntryCard(context, entry, isOwner)),
            const SizedBox(height: 12),
            if (isWorker)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogTimeDialog(context),
                  icon: const Icon(Icons.add_alarm_outlined),
                  label: const Text("Log Hours"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                        color: CustomColors.textMuted.withValues(alpha: 0.2)),
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
    final dateFormat = intl.DateFormat('MMM dd, yyyy');
    final timeFormat = intl.DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomColors.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${entry.hours.toStringAsFixed(1)} Hours",
                style: const TextStyle(
                  color: CustomColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildStatusChip(entry.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${dateFormat.format(entry.startTime)} | ${timeFormat.format(entry.startTime)} - ${timeFormat.format(entry.endTime)}",
            style: const TextStyle(color: CustomColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            entry.description,
            style: const TextStyle(color: CustomColors.textMain, fontSize: 14),
          ),
          if (isOwner && entry.status == TimeEntryStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _updateStatus(
                        context, entry.id, TimeEntryStatus.rejected),
                    child: const Text("Reject",
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(
                        context, entry.id, TimeEntryStatus.approved),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(TimeEntryStatus status) {
    Color color;
    switch (status) {
      case TimeEntryStatus.approved:
        color = Colors.green;
        break;
      case TimeEntryStatus.rejected:
        color = Colors.redAccent;
        break;
      case TimeEntryStatus.pending:
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showLogTimeDialog(BuildContext context) {
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CustomColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Log Work Hours",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text("Date"),
                subtitle:
                    Text(intl.DateFormat('MMM dd, yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setModalState(() => selectedDate = date);
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text("Start"),
                      subtitle: Text(startTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                            context: context, initialTime: startTime);
                        if (time != null) setModalState(() => startTime = time);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text("End"),
                      subtitle: Text(endTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                            context: context, initialTime: endTime);
                        if (time != null) setModalState(() => endTime = time);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  hintText: "What did you work on?",
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (descController.text.isEmpty) return;

                    final start = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        startTime.hour,
                        startTime.minute);
                    var end = DateTime(selectedDate.year, selectedDate.month,
                        selectedDate.day, endTime.hour, endTime.minute);
                    if (end.isBefore(start))
                      end = end.add(const Duration(days: 1));

                    final entry = TimeEntry(
                      id: '',
                      projectId: project.id,
                      workerId: project.workerId,
                      startTime: start,
                      endTime: end,
                      description: descController.text,
                    );

                    await context
                        .read<JobProvider>()
                        .logTime(project.id, entry);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Submit Hours"),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, String entryId, TimeEntryStatus status) async {
    await context
        .read<JobProvider>()
        .updateTimeEntryStatus(project.id, entryId, status);
  }
}

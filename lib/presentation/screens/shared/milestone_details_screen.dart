import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/theme/custom_colors.dart';
import 'package:work_hub/data/models/milestone_model.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import '../owner/escrow_deposit_screen.dart';

class MilestoneDetailsScreen extends StatefulWidget {
  final Milestone milestone;
  final bool isOwner;

  const MilestoneDetailsScreen({
    super.key,
    required this.milestone,
    required this.isOwner,
  });

  @override
  State<MilestoneDetailsScreen> createState() => _MilestoneDetailsScreenState();
}

class _MilestoneDetailsScreenState extends State<MilestoneDetailsScreen> {
  final _submissionNoteController = TextEditingController();
  final _linkController = TextEditingController();
  final _revisionNoteController = TextEditingController();

  Milestone get milestone => widget.milestone;

  @override
  Widget build(BuildContext context) {
    final project = context.watch<JobProvider>().projects.firstWhere(
          (p) => p.id == milestone.projectId,
          orElse: () => throw Exception("Project not found"),
        );
    final hasEnoughBalance = project.escrowBalance >= milestone.amount;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text(
          "Milestone Details",
          style: TextStyle(color: CustomColors.darkText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CustomColors.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDescription(),
            const SizedBox(height: 32),
            if (milestone.status == MilestoneStatus.submitted ||
                milestone.status == MilestoneStatus.approved)
              _buildSubmissionView(),
            if (milestone.status == MilestoneStatus.revisionRequested)
              _buildRevisionFeedback(),
            const SizedBox(height: 32),
            if (widget.isOwner &&
                milestone.status == MilestoneStatus.submitted &&
                !hasEnoughBalance)
              _buildInsufficientFundsWarning(project),
            const SizedBox(height: 40),
            _buildActionButtons(hasEnoughBalance),
          ],
        ),
      ),
    );
  }

  Widget _buildInsufficientFundsWarning(project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Insufficient Escrow Balance",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You need ₹${(milestone.amount - project.escrowBalance).toStringAsFixed(2)} more to approve this.",
                      style: const TextStyle(
                        color: CustomColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EscrowDepositScreen(project: project),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text("Deposit Funds Now"),
              style: TextButton.styleFrom(
                foregroundColor: CustomColors.primaryBlue,
                backgroundColor:
                    CustomColors.primaryBlue.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    Color statusColor;
    String statusText = milestone.status.name.toUpperCase();

    switch (milestone.status) {
      case MilestoneStatus.pending:
        statusColor = Colors.grey;
        break;
      case MilestoneStatus.submitted:
        statusColor = Colors.orange;
        break;
      case MilestoneStatus.approved:
        statusColor = Colors.green;
        break;
      case MilestoneStatus.revisionRequested:
        statusColor = Colors.redAccent;
        statusText = "REVISION REQUESTED";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                "₹${milestone.amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            milestone.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: CustomColors.textMuted),
              const SizedBox(width: 8),
              Text(
                "Deadline: ${_formatDate(milestone.deadline)}",
                style: const TextStyle(color: CustomColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Description",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          milestone.description,
          style: const TextStyle(
            color: CustomColors.textMain,
            height: 1.5,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_turned_in, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                "Work Submitted",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            milestone.submissionNote ?? "No notes provided.",
            style: const TextStyle(color: CustomColors.darkText),
          ),
          if (milestone.attachments != null &&
              milestone.attachments!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: milestone.attachments!
                    .map((link) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.link,
                                  size: 16, color: CustomColors.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  link,
                                  style: const TextStyle(
                                    color: CustomColors.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRevisionFeedback() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                "Revision Requested",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            milestone.revisionNote ?? "No feedback provided.",
            style: const TextStyle(color: CustomColors.darkText),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool hasEnoughBalance) {
    if (widget.isOwner) {
      if (milestone.status == MilestoneStatus.submitted) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: hasEnoughBalance ? _showApproveDialog : null,
                icon: const Icon(Icons.check_circle),
                label: const Text("Approve & Release Funds"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showRejectDialog,
                icon: const Icon(Icons.refresh),
                label: const Text("Request Revision"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    } else {
      // Worker
      if (milestone.status == MilestoneStatus.pending ||
          milestone.status == MilestoneStatus.revisionRequested) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _showSubmitWorkDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text("Submit Work"),
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _showSubmitWorkDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CustomColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
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
              "Submit Work",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CustomColors.darkText,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _submissionNoteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Notes",
                hintText: "Describe what you've done...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: "Project Link (Optional)",
                prefixIcon: const Icon(Icons.link),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final note = _submissionNoteController.text;
                  final link = _linkController.text;
                  final links = link.isNotEmpty ? [link] : <String>[];

                  if (note.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please add a note")),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await context.read<JobProvider>().submitMilestoneWork(
                        milestone.projectId,
                        milestone.id,
                        note,
                        links,
                      );
                  // Optionally refresh or pop
                  if (mounted) Navigator.pop(context); // Go back to list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Submit for Review"),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Approve Milestone?"),
        content: Text(
          "This will release ₹${milestone.amount.toStringAsFixed(2)} from the escrow to the worker. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<JobProvider>().approveMilestone(
                      milestone.projectId,
                      milestone.id,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Milestone approved and funds released!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve"),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Revision"),
        content: TextField(
          controller: _revisionNoteController,
          decoration: const InputDecoration(
            hintText: "Reason for revision...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_revisionNoteController.text.isEmpty) return;
              Navigator.pop(context);
              await context.read<JobProvider>().rejectMilestone(
                    milestone.projectId,
                    milestone.id,
                    _revisionNoteController.text,
                  );
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Request Revision"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

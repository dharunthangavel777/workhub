import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/core/theme/custom_colors.dart';

import 'package:work_hub/features/job/logic/job_controller.dart';
import 'package:work_hub/features/freelance/models/milestone.dart';

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

  Milestone get milestone => widget.milestone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
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

  Widget _buildActionButtons() {
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
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
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
                  foregroundColor: Colors.white,
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}




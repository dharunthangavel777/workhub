import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:work_hub/theme/custom_colors.dart';
import 'package:work_hub/data/models/milestone_model.dart';
import 'package:work_hub/data/models/project_model.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import '../../screens/owner/create_milestone_screen.dart';
import 'milestone_details_screen.dart';

class MilestoneListScreen extends StatefulWidget {
  final ProjectModel project;

  const MilestoneListScreen({super.key, required this.project});

  @override
  State<MilestoneListScreen> createState() => _MilestoneListScreenState();
}

class _MilestoneListScreenState extends State<MilestoneListScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to milestones when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().listenToMilestones(widget.project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final milestones = context.watch<JobProvider>().milestones;
    final isLoading = context.watch<JobProvider>().isLoading;
    final currentUser = context.watch<AuthProvider>().userModel;
    final isOwner = currentUser?.uid == widget.project.ownerId;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text(
          "Project Milestones",
          style: TextStyle(color: CustomColors.darkText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CustomColors.darkText),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateMilestoneScreen(
                      projectId: widget.project.id,
                      projectBudget: widget.project.budget ?? 0.0,
                    ),
                  ),
                );
              },
              backgroundColor: CustomColors.primaryBlue,
              icon: const Icon(Icons.add),
              label: const Text("Add Milestone"),
            )
          : null,
      body: isLoading && milestones.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : milestones.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: milestones.length,
                  itemBuilder: (context, index) {
                    final milestone = milestones[index];
                    return _buildMilestoneCard(milestone, index, isOwner);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.flagCheckered,
            size: 60,
            color: CustomColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "No milestones yet",
            style: TextStyle(
              fontSize: 18,
              color: CustomColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create milestones to track project progress",
            style: TextStyle(color: CustomColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Milestone milestone, int index, bool isOwner) {
    Color statusColor;
    IconData statusIcon;

    switch (milestone.status) {
      case MilestoneStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        break;
      case MilestoneStatus.submitted:
        statusColor = Colors.orange;
        statusIcon = Icons.assignment_turned_in;
        break;
      case MilestoneStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case MilestoneStatus.revisionRequested:
        statusColor = Colors.redAccent;
        statusIcon = Icons.warning;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MilestoneDetailsScreen(
                milestone: milestone,
                isOwner: context.read<AuthProvider>().userModel?.uid ==
                    widget.project.ownerId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          milestone.status.name.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${milestone.amount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CustomColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                milestone.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                milestone.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CustomColors.textMain,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: CustomColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    "Due: ${_formatDate(milestone.deadline)}",
                    style: const TextStyle(
                      color: CustomColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (!milestone.workerAgreed &&
                  !isOwner &&
                  milestone.status == MilestoneStatus.pending) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Do you agree to these requirements and deadline?",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<JobProvider>().updateMilestoneAgreedStatus(
                              widget.project.id,
                              milestone.id,
                              true,
                            );
                      },
                      child: const Text("AGREE"),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../data/models/job_post_model.dart';
import '../../../data/models/project_post_model.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../profile/profile_screen.dart';

class ApplicantsListScreen extends StatelessWidget {
  final dynamic job; // JobPostModel or ProjectPostModel
  final String mode;

  const ApplicantsListScreen({
    super.key,
    required this.job,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final applicants = job.applicants ?? {};
    final isFreelancer = mode == 'freelancer';

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: Text(
          isFreelancer
              ? "Bids for ${job is ProjectPostModel ? (job as ProjectPostModel).projectTitle : (job as JobPostModel).jobTitle}"
              : "Applicants for ${job is JobPostModel ? (job as JobPostModel).jobTitle : (job as ProjectPostModel).projectTitle}",
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: applicants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: CustomColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No applicants yet",
                    style: TextStyle(color: CustomColors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                final userId = applicants.keys.elementAt(index);
                final data = applicants.values.elementAt(index);
                return _ApplicantCard(
                  userId: userId,
                  data: data,
                  job: job,
                  mode: mode,
                );
              },
            ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;
  final dynamic job;
  final String mode;

  const _ApplicantCard({
    required this.userId,
    required this.data,
    required this.job,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final isHired = status == 'hired' || status == 'approved';
    final isRejected = status == 'rejected';
    final isFreelancer = mode == 'freelancer';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CustomColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHired
              ? Colors.green.withValues(alpha: 0.3)
              : (isRejected
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: userId),
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      CustomColors.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    (data['workerName'] ?? "U")[0].toUpperCase(),
                    style: const TextStyle(
                      color: CustomColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['workerName'] ?? "Anonymous User",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.darkText,
                      ),
                    ),
                    Text(
                      isFreelancer
                          ? "Bid: ₹${data['bidAmount'] ?? 0}"
                          : "Applied for ${job is JobPostModel ? (job as JobPostModel).jobCategory : (job as ProjectPostModel).projectCategory}",
                      style: const TextStyle(
                        color: CustomColors.primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          if (isFreelancer && data['proposal'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              "Proposal",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: CustomColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['proposal'],
              style: const TextStyle(
                color: CustomColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (isFreelancer &&
              data['suggestedMilestones'] != null &&
              (data['suggestedMilestones'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "Suggested Milestones",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: CustomColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            ...(data['suggestedMilestones'] as List).map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: CustomColors.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m['title'],
                          style: const TextStyle(
                              fontSize: 13, color: CustomColors.darkText),
                        ),
                      ),
                      Text(
                        "₹${m['amount']}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: CustomColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 20),
          if (!isHired && !isRejected)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, "rejected"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(context, "hired"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Hire Now"),
                  ),
                ),
              ],
            )
          else if (isHired)
            const Center(
              child: Text(
                "Successfully Hired",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'hired' || status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) async {
    final provider = context.read<JobProvider>();
    final auth = context.read<AuthProvider>();

    final title = job is JobPostModel
        ? (job as JobPostModel).jobTitle
        : (job as ProjectPostModel).projectTitle;
    final description = job is JobPostModel
        ? (job as JobPostModel).jobSummary
        : (job as ProjectPostModel).projectDescription;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      if (action == "hired") {
        if (mode == 'freelancer') {
          // Transitional flow for projects
          await provider.approveBid(
            postId: job.id,
            workerId: userId,
            workerName: data['workerName'] ?? "Worker",
            title: title,
            description: description,
            ownerId: auth.userModel?.uid ?? '',
            mode: mode,
            bidAmount: (data['bidAmount'] as num?)?.toDouble(),
            depositAmount: job is ProjectPostModel
                ? (job as ProjectPostModel).depositAmount
                : null,
            termsAndConditions: job is ProjectPostModel
                ? (job as ProjectPostModel).termsAndConditions
                : null,
            suggestedMilestones:
                data['suggestedMilestones'], // Pass suggested milestones
            deliveryTime: data['deliveryTime'],
          );
        } else {
          // Standard job hiring
          await provider.updateApplicationStatus(job.id, userId, "hired");
        }
      } else {
        await provider.updateApplicationStatus(job.id, userId, action);
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'hired'
                  ? "Successfully hired ${data['workerName'] ?? 'applicant'}!"
                  : "Applicant rejected successfully",
            ),
            backgroundColor: action == 'hired' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${e.toString()}",
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Log error for debugging
      debugPrint("Error in _handleAction: $e");
    }
  }
}

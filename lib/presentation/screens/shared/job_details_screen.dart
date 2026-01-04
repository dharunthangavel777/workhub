import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/custom_colors.dart';
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
    final user = context.watch<AuthProvider>().userModel;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFreelancer = user.activeMode == 'freelancer';

    final title = isJob ? jobPost.jobTitle : projectPost.projectTitle;
    final companyName = isJob
        ? jobPost.companyName
        : (projectPost.companyName ?? "Freelance Project");
    final logoUrl = isJob ? jobPost.companyLogo : projectPost.companyLogo;
    final ownerName = isJob ? jobPost.ownerName : projectPost.ownerName;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [CustomColors.primaryBlue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'logo-${isJob ? jobPost.id : projectPost.id}',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: logoUrl != null && logoUrl.isNotEmpty
                          ? NetworkImage(logoUrl)
                          : null,
                      child: (logoUrl == null || logoUrl.isEmpty)
                          ? Text(
                              companyName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: CustomColors.primaryBlue,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.darkText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    companyName,
                    style: const TextStyle(
                        fontSize: 18,
                        color: CustomColors.primaryBlue,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Snapshot row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _snapshotItem(
                        Icons.business_center_outlined,
                        isJob
                            ? "${jobPost.experienceMin}-${jobPost.experienceMax} yrs"
                            : projectPost.experienceLevel,
                      ),
                      _snapshotItem(
                        Icons.payments_outlined,
                        isJob
                            ? "${jobPost.salaryMin}-${jobPost.salaryMax} ${jobPost.salaryType}"
                            : "${projectPost.budgetMin}-${projectPost.budgetMax}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _snapshotItem(Icons.location_on_outlined,
                          isJob ? jobPost.jobLocation : "Remote"),
                      if ((isJob
                              ? jobPost.deadlineDate
                              : projectPost.deadlineDate) !=
                          null)
                        _snapshotItem(
                          Icons.calendar_today_outlined,
                          "Ends: ${(isJob ? jobPost.deadlineDate! : projectPost.deadlineDate!).toLocal().toString().split(' ')[0]}",
                        )
                      else
                        _snapshotItem(Icons.home_work_outlined,
                            isJob ? jobPost.workMode : projectPost.projectType),
                    ],
                  ),
                  const Divider(height: 48, color: Colors.black12),

                  // Posted By section
                  if (ownerName != null) ...[
                    _sectionTitle("Posted By", size: 16),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_pin,
                            color: CustomColors.primaryBlue, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ownerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: CustomColors.darkText,
                              ),
                            ),
                            Text(
                              isJob ? jobPost.companyName : "Project Owner",
                              style: const TextStyle(
                                color: CustomColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 48, color: Colors.black12),
                  ],

                  // Content sections
                  if (isJob)
                    ..._buildJobContent()
                  else
                    ..._buildProjectContent(),

                  const SizedBox(height: 32),
                  _sectionTitle("Skills Required"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (isJob
                            ? jobPost.requiredSkills
                            : projectPost.requiredSkills)
                        .map((s) {
                      final iconUrl = SkillIconUtils.getIconUrl(s);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: CustomColors.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (iconUrl != null) ...[
                              SvgPicture.network(
                                iconUrl,
                                width: 16,
                                height: 16,
                                placeholderBuilder: (context) => const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(s,
                                style: const TextStyle(
                                    color: CustomColors.darkText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CustomColors.lightCard,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 5)
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: _buildBottomButton(context, user, isFreelancer),
        ),
      ),
    );
  }

  Widget _buildBottomButton(
      BuildContext context, dynamic user, bool isFreelancer) {
    // Check if worker is already hired for this project
    String? status;
    if (isJob) {
      status = jobPost.applicants?[user.uid]?['status'];
    } else {
      status = projectPost.applicants?[user.uid]?['status'];
    }

    if (status?.toLowerCase() == 'approved') {
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
                builder: (context) => ProjectDashboardScreen(project: project),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Project dashboard is being prepared...")),
            );
          }
        },
        icon: const Icon(Icons.dashboard_outlined),
        label: const Text("Go to Project Dashboard"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
        ),
      );
    }

    return ElevatedButton(
      onPressed: () {
        // --- CHECK LIMITS ---
        final deadline =
            isJob ? jobPost.deadlineDate : projectPost.deadlineDate;
        final maxApps =
            isJob ? jobPost.maxApplications : projectPost.maxApplications;
        final currentApps = isJob
            ? (jobPost.applicants?.length ?? 0)
            : (projectPost.applicants?.length ?? 0);

        if (deadline != null && DateTime.now().isAfter(deadline)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Applications are closed for this post (Deadline Reached).")),
          );
          return;
        }

        if (maxApps != null && currentApps >= maxApps) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Applications are closed for this post (Maximum Limit Reached).")),
          );
          return;
        }

        if (user.profileCompletion < 95) {
          _showIncompleteProfileDialog(context, user);
          return;
        }

        if (isFreelancer) {
          _showBidForm(context, post, user.uid, user.displayName);
        } else {
          _showApplyConfirmation(context, post, user.uid, user.displayName);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _isPostClosed() ? Colors.grey : null,
      ),
      child: Text(_getButtonText(isFreelancer)),
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

  String _getButtonText(bool isFreelancer) {
    if (_isPostClosed()) return "Applications Closed";
    return isFreelancer ? "Place a Bid" : "Apply to this Job";
  }

  void _showIncompleteProfileDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CustomColors.lightCard,
        title: const Text("Profile Incomplete"),
        content: Text(
            "Your profile is only ${user.profileCompletion}% complete.\n\nYou need 95% completion to apply or bid. Please ensure you have:\n• Basic Details & Bio\n• Skills\n• Resume"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK",
                style: TextStyle(color: CustomColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildJobContent() {
    return [
      _sectionTitle("Job Description"),
      const SizedBox(height: 12),
      Text(jobPost.jobSummary,
          style: const TextStyle(color: CustomColors.textMuted, height: 1.6)),
      const SizedBox(height: 24),
      _sectionTitle("Responsibilities"),
      const SizedBox(height: 12),
      Text(jobPost.responsibilities,
          style: const TextStyle(color: CustomColors.textMuted, height: 1.6)),
      const SizedBox(height: 24),
      _sectionTitle("Requirements"),
      const SizedBox(height: 12),
      _detailRow("Employment", jobPost.employmentType),
      _detailRow("Shift", jobPost.shiftType ?? "Not Specified"),
      _detailRow("Openings", "${jobPost.openings}"),
      _detailRow("Education", jobPost.education),
    ];
  }

  List<Widget> _buildProjectContent() {
    return [
      _sectionTitle("Project Description"),
      const SizedBox(height: 12),
      Text(projectPost.projectDescription,
          style: const TextStyle(color: CustomColors.textMuted, height: 1.6)),
      const SizedBox(height: 24),
      _sectionTitle("Project Details"),
      const SizedBox(height: 12),
      _detailRow("Duration", projectPost.projectDuration),
      _detailRow("Type", projectPost.projectType),
      _detailRow("NDA Required", projectPost.ndaRequired ? "Yes" : "No"),
    ];
  }

  Widget _snapshotItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: CustomColors.textMuted),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: CustomColors.darkText, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _sectionTitle(String title, {double size = 18}) {
    return Text(title,
        style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(color: CustomColors.textMuted))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: CustomColors.darkText,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showApplyConfirmation(
      BuildContext context, dynamic post, String userId, String userName) {
    final title = post is JobPostModel ? post.jobTitle : post.projectTitle;
    final postId = post is JobPostModel ? post.id : post.id;
    final isJobPost = post is JobPostModel;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CustomColors.lightCard,
        title: const Text("Confirm Application"),
        content: Text("Proceed with application for $title?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (isJobPost) {
                await context
                    .read<JobProvider>()
                    .apply(postId, userId, userName);
              } else {
                // Projects usually use bids
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Application successful!")));
              }
            },
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
      backgroundColor: CustomColors.lightCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void calculateTotal() {
            double total = 0;
            for (var m in suggestedMilestones) {
              total += (m['amount'] as num).toDouble();
            }
            amountController.text = total.toStringAsFixed(2);
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Submit Your Proposal",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CustomColors.darkText)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    readOnly: suggestedMilestones.isNotEmpty,
                    decoration: InputDecoration(
                        labelText: "Total Bid Amount",
                        hintText: suggestedMilestones.isNotEmpty
                            ? "Calculated from milestones"
                            : "Enter your quote",
                        filled: suggestedMilestones.isNotEmpty,
                        fillColor: Colors.grey.shade50),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: timelineController,
                    decoration: const InputDecoration(
                        labelText: "Overall Timeline", hintText: "e.g. 5 days"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: proposalController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: "Proposal",
                        hintText: "Why should they hire you?"),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Suggested Milestones",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.darkText)),
                      TextButton.icon(
                        onPressed: () {
                          _showAddMilestoneDialog(context, (m) {
                            setModalState(() {
                              suggestedMilestones.add(m);
                              calculateTotal();
                            });
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (suggestedMilestones.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Suggestion: Break your bid into milestones to build trust.",
                        style: TextStyle(
                            fontSize: 12, color: CustomColors.textMuted),
                      ),
                    )
                  else
                    ...suggestedMilestones.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final m = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m['title'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  Text("₹${m['amount']}",
                                      style: const TextStyle(
                                          color: CustomColors.primaryBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.redAccent),
                              onPressed: () {
                                setModalState(() {
                                  suggestedMilestones.removeAt(idx);
                                  calculateTotal();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
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
                                    content: Text("Bid submitted!")));
                          }
                        }
                      },
                      child: const Text("Place Bid"),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddMilestoneDialog(
      BuildContext context, Function(Map<String, dynamic>) onAdd) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CustomColors.lightCard,
        title: const Text("Add Suggested Milestone"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Milestone Title",
                hintText: "e.g. initial Draft",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (₹)",
                hintText: "e.g. 100",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                onAdd({
                  'title': titleController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'description': 'As suggested in bid',
                  'deadline': DateTime.now()
                      .add(const Duration(days: 7))
                      .millisecondsSinceEpoch,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/custom_colors.dart';
import '../../data/models/job_post_model.dart';
import '../../../../data/models/project_post_model.dart';
import '../../../core/utils/image_constant.dart';
import '../widgets/shared/custom_image_view.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String category;
  final String salaryOrBudget;
  final List<String> requiredSkills;
  final String? experienceOrLevel;
  final String? type; // 'job' or 'project'
  final String? workMode;
  final String? companyLogo;
  final String? ownerName;
  final String? ownerPhoto;
  final bool isPromoted;
  final bool isBookmarked;
  final bool isClosed;
  final bool isVerified;
  final int? openings;
  final int? applicationsCount;
  final int? maxApplications;
  final VoidCallback? onBookmarkToggle;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.category,
    required this.salaryOrBudget,
    required this.requiredSkills,
    this.experienceOrLevel,
    this.type,
    this.workMode,
    this.companyLogo,
    this.ownerName,
    this.ownerPhoto,
    this.isPromoted = false,
    this.isBookmarked = false,
    this.isClosed = false,
    this.isVerified = false,
    this.openings,
    this.applicationsCount,
    this.maxApplications,
    this.onBookmarkToggle,
  });

  factory JobCard.fromJobPost(JobPostModel job) {
    return JobCard(
      title: job.jobTitle,
      company: job.companyName,
      location: job.jobLocation,
      category: job.jobCategory,
      salaryOrBudget: job.salaryMin != null
          ? "${job.salaryMin} - ${job.salaryMax} ${job.salaryType}"
          : "Not Disclosed",
      requiredSkills: job.requiredSkills,
      experienceOrLevel: "${job.experienceMin}-${job.experienceMax} yrs",
      type: 'job',
      workMode: job.workMode,
      companyLogo: job.companyLogo,
      ownerName: job.ownerName,
      ownerPhoto: job.ownerPhoto,
      isVerified: job.isVerified,
      openings: job.openings,
      isClosed: (job.deadlineDate != null &&
              DateTime.now().isAfter(job.deadlineDate!)) ||
          (job.maxApplications != null &&
              job.applicationsCount >= job.maxApplications!),
      applicationsCount: job.applicationsCount,
      maxApplications: job.maxApplications,
    );
  }

  factory JobCard.fromProjectPost(ProjectPostModel project) {
    return JobCard(
      title: project.projectTitle,
      company: project.companyName ?? "Freelance Project",
      location: project.projectLocation,
      category: project.projectCategory,
      salaryOrBudget: "${project.budgetMin} - ${project.budgetMax}",
      requiredSkills: project.requiredSkills,
      experienceOrLevel: project.experienceLevel,
      type: 'project',
      workMode: project.workMode,
      companyLogo: project.companyLogo,
      ownerName: project.ownerName,
      ownerPhoto: project.ownerPhoto,
      isVerified: project.isVerified,
      isClosed: (project.deadlineDate != null &&
              DateTime.now().isAfter(project.deadlineDate!)) ||
          (project.maxApplications != null &&
              project.applicationsCount >= project.maxApplications!),
      applicationsCount: project.applicationsCount,
      maxApplications: project.maxApplications,
    );
  }

  JobCard copyWith({
    bool? isBookmarked,
    VoidCallback? onBookmarkToggle,
  }) {
    return JobCard(
      title: title,
      company: company,
      location: location,
      category: category,
      salaryOrBudget: salaryOrBudget,
      requiredSkills: requiredSkills,
      experienceOrLevel: experienceOrLevel,
      type: type,
      workMode: workMode,
      companyLogo: companyLogo,
      ownerName: ownerName,
      ownerPhoto: ownerPhoto,
      isPromoted: isPromoted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isClosed: isClosed,
      isVerified: isVerified,
      openings: openings,
      applicationsCount: applicationsCount,
      maxApplications: maxApplications,
      onBookmarkToggle: onBookmarkToggle ?? this.onBookmarkToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPromoted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        SizedBox(width: 4),
                        Text(
                          "FEATURED",
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isClosed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 12),
                        SizedBox(width: 4),
                        Text(
                          "CLOSED",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        companyLogo != null && companyLogo!.isNotEmpty
                            ? NetworkImage(companyLogo!)
                            : null,
                    child: (companyLogo == null || companyLogo!.isEmpty)
                        ? Text(
                            company[0].toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: CustomColors.primaryBlue),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CustomColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              company,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CustomColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isVerified) ...[
                              SizedBox(width: 4),
                              CustomImageView(
                                imagePath: ImageConstant.imgMdiTickDecagram,
                                height: 14,
                                width: 14,
                                color: CustomColors.primaryBlue,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onBookmarkToggle,
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? CustomColors.primaryBlue
                          : CustomColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _infoItem(
                    Icons.business_center_outlined,
                    experienceOrLevel ?? "N/A",
                  ),
                  const SizedBox(width: 16),
                  _infoItem(Icons.payments_outlined, salaryOrBudget),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoItem(
                    Icons.location_on_outlined,
                    location,
                    workMode: workMode,
                  ),
                  const SizedBox(width: 16),
                  _infoItem(Icons.category_outlined, category),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (type == 'job' && openings != null) ...[
                    _infoItem(Icons.person_outline, "$openings Vacancies",
                        iconColor: CustomColors.primaryBlue),
                    const SizedBox(width: 16),
                  ],
                  if (type == 'project' && maxApplications != null) ...[
                    _infoItem(Icons.person_outline, "$maxApplications Limit",
                        iconColor: CustomColors.primaryBlue),
                    const SizedBox(width: 16),
                  ],
                  if (applicationsCount != null)
                    _infoItem(
                        Icons.groups_outlined,
                        type == 'job'
                            ? "$applicationsCount Applications"
                            : "$applicationsCount Proposals",
                        iconColor: CustomColors.primaryBlue),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...requiredSkills.take(3).map(
                            (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CustomColors.primaryBlue
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: CustomColors.primaryBlue
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  color: CustomColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                  if (ownerName != null)
                    Row(
                      children: [
                        const Text("by ",
                            style: TextStyle(
                                color: CustomColors.textMuted, fontSize: 10)),
                        const Icon(Icons.person_pin,
                            size: 14, color: CustomColors.primaryBlue),
                        const SizedBox(width: 4),
                        Text(
                          ownerName!,
                          style: const TextStyle(
                            color: CustomColors.darkText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        if (type != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (type == 'project'
                        ? Colors.purple
                        : CustomColors.primaryBlue)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type == 'project' ? "PROJECT" : "JOB",
                style: TextStyle(
                  color: type == 'project'
                      ? Colors.purpleAccent
                      : CustomColors.successGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String text,
      {String? workMode, Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor ?? CustomColors.textMuted),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: CustomColors.textMuted, fontSize: 12),
            children: [
              TextSpan(text: text),
              if (workMode != null) ...[
                const TextSpan(text: " • "),
                TextSpan(
                  text: workMode,
                  style: const TextStyle(color: CustomColors.successGreen),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

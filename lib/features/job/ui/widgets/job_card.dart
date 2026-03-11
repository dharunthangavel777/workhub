import 'package:flutter/material.dart';
import 'package:work_hub/core/widgets/custom_image_view.dart';
import 'package:work_hub/features/job/domain/models/job.dart';
import 'package:google_fonts/google_fonts.dart';

class JobCard extends StatefulWidget {
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
  final String? postImage;
  final String? timeAgo;
  final String? projectDuration;
  final String? rating;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onTap;

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
    this.postImage,
    this.timeAgo,
    this.projectDuration,
    this.rating,
    this.onBookmarkToggle,
    this.onTap,
  });

  static String _formatBudget(int? min, int? max, bool isJob) {
    if (min == null || max == null) return "Not Disclosed";

    if (isJob) {
      // Annual Salary in LPA (Lakhs Per Annum)
      // Assuming values are stored as raw amounts (e.g., 500000) or direct Lakhs (e.g., 5)
      // We'll normalize: if > 1000, divide by 100k
      String formatLPA(int val) {
        if (val >= 1000) {
          double lpa = val / 100000;
          return lpa.toStringAsFixed(lpa == lpa.toInt() ? 0 : 1);
        }
        return val.toString();
      }

      return "₹${formatLPA(min)} - ₹${formatLPA(max)} LPA";
    } else {
      // Project budget in 'k' notation
      String formatK(int val) {
        if (val >= 1000) {
          int k = (val / 1000).floor();
          return "${k}k";
        }
        return val.toString();
      }

      return "₹${formatK(min)} - ₹${formatK(max)}";
    }
  }

  factory JobCard.fromJobPost(Job job) {
    return JobCard(
      title: job.title,
      company: job.companyName ?? "Unknown Company",
      location: job.location,
      category: job.category,
      salaryOrBudget: _formatBudget(job.budgetMin, job.budgetMax, true),
      requiredSkills: job.requiredSkills,
      type: 'job',
      workMode: job.workMode,
      companyLogo: job.companyLogo,
      ownerName: job.ownerName,
      ownerPhoto: job.ownerPhoto,
      isVerified: job.isVerified,
      openings: job.openings,
      isClosed: job.status == 'filled' || job.status == 'closed',
      applicationsCount: job.applicationsCount,
      maxApplications: job.maxApplications,
      postImage: job.postImage,
      timeAgo: _calculateTimeAgo(job.createdAt),
      rating: "4.8",
      experienceOrLevel: job.experienceLevel,
    );
  }

  factory JobCard.fromProjectPost(Job project) {
    return JobCard(
      title: project.title,
      company: project.companyName ?? "Freelance Project",
      location: project.location,
      category: project.category,
      salaryOrBudget:
          _formatBudget(project.budgetMin, project.budgetMax, false),
      requiredSkills: project.requiredSkills,
      type: 'project',
      workMode: project.workMode,
      companyLogo: project.companyLogo,
      ownerName: project.ownerName,
      ownerPhoto: project.ownerPhoto,
      isVerified: project.isVerified,
      isClosed: project.status == 'filled' || project.status == 'closed',
      applicationsCount: project.applicationsCount,
      maxApplications: project.maxApplications,
      postImage: project.postImage,
      timeAgo: _calculateTimeAgo(project.createdAt),
      rating: "4.9",
      experienceOrLevel: project.experienceLevel,
      projectDuration: project.projectDuration,
    );
  }

  static String _calculateTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'Just now';
  }

  JobCard copyWith({
    bool? isBookmarked,
    VoidCallback? onBookmarkToggle,
    VoidCallback? onTap,
  }) {
    return JobCard(
      key: key,
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
      postImage: postImage ?? this.postImage,
      timeAgo: timeAgo ?? timeAgo,
      projectDuration: projectDuration ?? projectDuration,
      rating: rating ?? rating,
      onBookmarkToggle: onBookmarkToggle ?? this.onBookmarkToggle,
      onTap: onTap ?? this.onTap,
    );
  }

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(JobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBookmarked && !oldWidget.isBookmarked) {
      _heartController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProject = widget.type == 'project';

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 160,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isProject ? _buildProjectStyle() : _buildJobStyle(),
        ),
      ),
    );
  }

  Widget _buildProjectStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo or Post Image
            Stack(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomImageView(
                      imagePath: widget.postImage ??
                          widget.companyLogo ??
                          widget.ownerPhoto,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (widget.postImage != null &&
                    (widget.companyLogo != null || widget.ownerPhoto != null))
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: CustomImageView(
                          imagePath: widget.companyLogo ?? widget.ownerPhoto,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.ownerName ?? widget.company,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFBBF24), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.rating ?? "4.9",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined,
                          color: Color(0xFF9CA3AF), size: 14),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          widget.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.people_outline,
                          color: Color(0xFF9CA3AF), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.applicationsCount ?? 0}/${widget.maxApplications ?? '∞'}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (widget.onBookmarkToggle != null) {
                  widget.onBookmarkToggle!();
                  if (!widget.isBookmarked) {
                    _heartController.forward(from: 0.0);
                  }
                }
              },
              child: ScaleTransition(
                scale: _heartScale,
                child: Icon(
                  widget.isBookmarked ? Icons.favorite : Icons.favorite_border,
                  color: widget.isBookmarked
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFD1D5DB),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _styleTag(widget.workMode == "Remote" ? "Online" : "Offline"),
              const SizedBox(width: 8),
              if (widget.experienceOrLevel != null) ...[
                _styleTag(widget.experienceOrLevel!),
                const SizedBox(width: 8),
              ],
              if (widget.projectDuration != null) ...[
                _styleTag(widget.projectDuration!),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "BUDGET",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.salaryOrBudget,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 12),
                Row(
                  children: [
                    Text(
                      "View Project",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000FE2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF000FE2), size: 12),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJobStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Square Logo or Post Image
            Stack(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomImageView(
                      imagePath: widget.postImage ??
                          widget.companyLogo ??
                          widget.ownerPhoto,
                      fit: BoxFit.cover,
                      margin: widget.postImage != null
                          ? EdgeInsets.zero
                          : const EdgeInsets.all(8),
                    ),
                  ),
                ),
                if (widget.postImage != null &&
                    (widget.companyLogo != null || widget.ownerPhoto != null))
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomImageView(
                          imagePath: widget.companyLogo ?? widget.ownerPhoto,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            color: Color(0xFF000FE2), size: 16),
                      ],
                    ],
                  ),
                  Text(
                    widget.company,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB800), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.rating ?? "4.8",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1D5DB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined,
                          color: Color(0xFF6B7280), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1D5DB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.people_outline,
                          color: Color(0xFF6B7280), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.applicationsCount ?? 0}/${widget.maxApplications ?? '∞'}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Heart icon
            GestureDetector(
              onTap: () {
                if (widget.onBookmarkToggle != null) {
                  widget.onBookmarkToggle!();
                  if (!widget.isBookmarked) {
                    _heartController.forward();
                  }
                }
              },
              child: ScaleTransition(
                scale: _heartScale,
                child: Icon(
                  widget.isBookmarked ? Icons.favorite : Icons.favorite_border,
                  color: widget.isBookmarked
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFD1D5DB),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Tags
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _styleTag(widget.workMode ?? "Remote"),
              const SizedBox(width: 8),
              _styleTag("Full-Time"),
              const SizedBox(width: 8),
              _styleTag(widget.salaryOrBudget),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Posted ${widget.timeAgo ?? '2h ago'}",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 16),
                Row(
                  children: [
                    Text(
                      "View Details",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000FE2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF000FE2), size: 16),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _styleTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }
}

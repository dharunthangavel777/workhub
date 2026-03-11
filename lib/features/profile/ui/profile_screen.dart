import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/features/job/logic/job_controller.dart';
import 'package:work_hub/features/auth/models/user.dart';
import 'package:work_hub/core/shared_widgets/universal_skeleton.dart';
import 'add_experience_screen.dart';
import 'add_portfolio_screen.dart';
import 'edit_profile_screen.dart';

import 'widgets/profile_header_delegate.dart';
import '../../ai/ui/resume_upload_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user's profile

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _fetchedUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserIfNeeded();
  }

  Future<void> _fetchUserIfNeeded() async {
    final auth = context.read<AuthProvider>();
    if (widget.userId != null && widget.userId != auth.userModel?.uid) {
      setState(() => _isLoading = true);
      final user = await auth.getUserById(widget.userId!);
      if (mounted) {
        setState(() {
          _fetchedUser = user;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider,
        ({UserModel? user, bool isLoading, String? myUid})>(
      selector: (_, auth) => (
        user: widget.userId == null || widget.userId == auth.userModel?.uid
            ? auth.userModel
            : _fetchedUser,
        isLoading: auth.isLoading,
        myUid: auth.userModel?.uid,
      ),
      builder: (context, data, _) {
        final user = data.user;
        final isCurrentUser =
            widget.userId == null || widget.userId == data.myUid;

        if ((isCurrentUser && data.isLoading) || _isLoading || user == null) {
          return Scaffold(
            body: UniversalSkeleton.profile(),
          );
        }

        return Scaffold(
          backgroundColor: CustomColors.lightBg,
          body: Stack(
            children: [
              CustomScrollView(
                cacheExtent: 1500,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: ProfileHeaderDelegate(
                      user: user,
                      isCurrentUser: isCurrentUser,
                      profileCompletion: (user.profileCompletion).toDouble(),
                      onSettingsTap: () =>
                          Navigator.pushNamed(context, '/settings'),
                      onBackTap: () => Navigator.pop(context),
                      onEditTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCurrentUser && user.profileCompletion < 100)
                            _buildProfileCompletionAlert(user),
                          if (isCurrentUser) ...[
                            SizedBox(height: 8.h),
                            const _ProfileSectionTitle(
                                title: "Wallet & Earnings"),
                            SizedBox(height: 12.h),
                            _buildWalletCard(context, user),
                            SizedBox(height: 32.h),
                          ],
                          _buildStatsSection(context, user),
                          SizedBox(height: 32.h),
                          const _ProfileSectionTitle(title: "Professional Bio"),
                          SizedBox(height: 12.h),
                          Text(
                            user.bio ?? "No bio added yet.",
                            style:
                                TextStyleHelper.instance.body14Medium.copyWith(
                              color: appTheme.gray_600,
                              height: 1.6,
                            ),
                          ),
                          SizedBox(height: 32.h),
                          _buildExperienceSection(context, user, isCurrentUser),
                          SizedBox(height: 32.h),
                          _buildProjectsSection(context, user, isCurrentUser),
                          SizedBox(height: 32.h),
                          _buildResumeSection(context, user, isCurrentUser),
                          SizedBox(height: 32.h),
                          const _ProfileSectionTitle(
                              title: "Skills & Expertise"),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: (user.skills ?? [])
                                .map((skill) => Chip(
                                      label: Text(skill),
                                      backgroundColor: appTheme.indigo_A700
                                          .withValues(alpha: 0.05),
                                      labelStyle: TextStyleHelper
                                          .instance.body12Bold
                                          .copyWith(
                                        color: appTheme.indigo_A700,
                                      ),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.h)),
                                    ))
                                .toList(),
                          ),
                          SizedBox(height: 32.h),
                          _buildCertificationsSection(context, user),
                          SizedBox(height: 32.h),
                          SizedBox(height: 32.h),
                          const _ProfileSectionTitle(title: "Achievements"),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              _BadgeIcon(
                                icon: FontAwesomeIcons.shieldHalved,
                                color: user.isVerified
                                    ? Colors.blue
                                    : appTheme.gray_300,
                                label: user.isVerified ? "Verified" : "Pending",
                              ),
                              SizedBox(width: 24.w),
                              const _BadgeIcon(
                                icon: FontAwesomeIcons.award,
                                color: Colors.amber,
                                label: "Top Rated",
                              ),
                            ],
                          ),
                          SizedBox(height: 32.h),
                          const _ProfileSectionTitle(title: "Reviews"),
                          SizedBox(height: 16.h),
                          _buildReviewsSection(context, user.uid),
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCompletionAlert(UserModel user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: appTheme.indigo_A700.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.indigo_A700.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: appTheme.indigo_A700, size: 20.h),
              SizedBox(width: 8.w),
              Text(
                "Profile ${user.profileCompletion}% Complete",
                style: TextStyleHelper.instance.body14Bold
                    .copyWith(color: appTheme.indigo_A700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "Add ${user.missingProfileFields.take(2).join(', ')} to stand out to employers.",
            style: TextStyleHelper.instance.body12Medium
                .copyWith(color: appTheme.gray_600),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, UserModel user) {
    return Container(
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: appTheme.indigo_A700,
        borderRadius: BorderRadius.circular(24.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.indigo_A700.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Available Balance",
                  style: TextStyleHelper.instance.body12Medium
                      .copyWith(color: Colors.white70),
                ),
                SizedBox(height: 4.h),
                Text(
                  "₹${user.walletBalance.toStringAsFixed(2)}",
                  style: TextStyleHelper.instance.headline30Bold
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/withdrawal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: appTheme.indigo_A700,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.h)),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            ),
            child: Text("Withdraw", style: TextStyleHelper.instance.body14Bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, UserModel user) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
              context,
              "Projects",
              Text(
                "${user.completedProjects}",
                style: TextStyleHelper.instance.body18Bold
                    .copyWith(color: appTheme.indigo_A700),
              )),
          _buildVerticalDivider(),
          Column(
            children: [
              Row(
                children: [
                  Text(
                    user.rating.toStringAsFixed(1),
                    style: TextStyleHelper.instance.body18Bold
                        .copyWith(color: appTheme.indigo_A700),
                  ),
                  SizedBox(width: 4.w),
                  CustomImageView(
                    imagePath: 'assets/icons/star.svg',
                    height: 14.h,
                    width: 14.h,
                    color: Colors.amber,
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                "Rating",
                style: TextStyleHelper.instance.body12Medium
                    .copyWith(color: appTheme.gray_500),
              ),
            ],
          ),
          _buildVerticalDivider(),
          _buildStatItem(
              context,
              "Earnings",
              Text(
                "₹${(user.totalEarnings).toStringAsFixed(0)}",
                style: TextStyleHelper.instance.body18Bold
                    .copyWith(color: appTheme.indigo_A700),
              )),
        ],
      ),
    );
  }

  Widget _buildExperienceSection(
      BuildContext context, UserModel user, bool isCurrentUser) {
    final experiences = user.experiences ?? [];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _ProfileSectionTitle(title: "Experience"),
            if (isCurrentUser)
              IconButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddExperienceScreen())),
                icon: Icon(Icons.add_circle, color: appTheme.indigo_A700),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        if (experiences.isEmpty)
          _buildEmptyPlaceholder("No experience added yet.")
        else
          ...experiences.map((exp) => Container(
                margin: EdgeInsets.only(bottom: 16.h),
                padding: EdgeInsets.all(16.h),
                decoration: BoxDecoration(
                  color: appTheme.gray_50,
                  borderRadius: BorderRadius.circular(16.h),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.h),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.h)),
                      child: Icon(Icons.business_center_outlined,
                          color: appTheme.indigo_A700),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp.title,
                              style: TextStyleHelper.instance.body16Bold),
                          Text(exp.company,
                              style: TextStyleHelper.instance.body14Medium
                                  .copyWith(color: appTheme.indigo_A700)),
                          SizedBox(height: 4.h),
                          Text(exp.duration,
                              style: TextStyleHelper.instance.body12Medium
                                  .copyWith(color: appTheme.gray_500)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildProjectsSection(
      BuildContext context, UserModel user, bool isCurrentUser) {
    final portfolio = user.portfolio?.values.whereType<Map>().toList() ?? [];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _ProfileSectionTitle(title: "Projects & Products"),
            if (isCurrentUser)
              IconButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddPortfolioScreen())),
                icon: Icon(Icons.add_circle, color: appTheme.indigo_A700),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        if (portfolio.isEmpty)
          _buildEmptyPlaceholder("No projects added yet.")
        else
          SizedBox(
            height: 180.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: portfolio.length,
              itemBuilder: (context, index) {
                final item = portfolio[index];
                return Container(
                  width: 200.w,
                  margin: EdgeInsets.only(right: 16.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.h),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomImageView(
                          imagePath: item['image'] ?? "",
                          fit: BoxFit.cover,
                          height: 180.h,
                          width: 200.w,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.8)
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.h),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              item['title'] ?? "Project",
                              style: TextStyleHelper.instance.body14Bold
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Text(message,
        style: TextStyleHelper.instance.body14Medium
            .copyWith(color: appTheme.gray_400));
  }

  Widget _buildStatItem(
      BuildContext context, String label, Widget valueWidget) {
    return Column(
      children: [
        valueWidget,
        SizedBox(height: 4.h),
        Text(label,
            style: TextStyleHelper.instance.body12Medium
                .copyWith(color: appTheme.gray_500)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30.h, width: 1, color: appTheme.gray_200);
  }

  Widget _buildReviewsSection(BuildContext context, String userId) {
    return StreamBuilder<List<dynamic>>(
      stream: context.read<JobProvider>().getReviewsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error loading reviews");
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!;
        if (reviews.isEmpty) {
          return Container(
            padding: EdgeInsets.all(24.h),
            decoration: BoxDecoration(
              color: appTheme.gray_50,
              borderRadius: BorderRadius.circular(16.h),
            ),
            child: Row(
              children: [
                Icon(Icons.rate_review_outlined, color: appTheme.gray_400),
                SizedBox(width: 12.w),
                Text(
                  "No reviews yet",
                  style: TextStyleHelper.instance.body14Medium
                      .copyWith(color: appTheme.gray_500),
                ),
              ],
            ),
          );
        }

        return Column(
          children: reviews.map((review) => _buildReviewCard(review)).toList(),
        );
      },
    );
  }

  Widget _buildResumeSection(
      BuildContext context, UserModel user, bool isCurrentUser) {
    final hasResume = user.resumeUrl != null && user.resumeUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProfileSectionTitle(title: "Resume & Insights"),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: appTheme.white_A700_01,
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(color: appTheme.gray_100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.h),
                    decoration: BoxDecoration(
                      color: hasResume
                          ? Colors.green.withValues(alpha: 0.1)
                          : appTheme.gray_100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasResume
                          ? Icons.description
                          : Icons.description_outlined,
                      color: hasResume ? Colors.green : appTheme.gray_400,
                      size: 24.h,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasResume ? "Resume Uploaded" : "No Resume Uploaded",
                          style: TextStyleHelper.instance.body16Bold,
                        ),
                        Text(
                          hasResume
                              ? "Last analyzed: ${user.createdAt?.day ?? 'N/A'}/${user.createdAt?.month ?? 'N/A'}/${user.createdAt?.year ?? 'N/A'}"
                              : "Upload your resume to get AI insights",
                          style: TextStyleHelper.instance.body12Medium
                              .copyWith(color: appTheme.gray_500),
                        ),
                      ],
                    ),
                  ),
                  if (hasResume)
                    IconButton(
                      onPressed: () => _launchURL(user.resumeUrl!),
                      icon: Icon(Icons.visibility_outlined,
                          color: appTheme.indigo_A700),
                    ),
                ],
              ),
              if (isCurrentUser) ...[
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ResumeUploadScreen()),
                    ),
                    icon: Icon(Icons.auto_awesome, size: 18.h),
                    label: Text(hasResume
                        ? "Update & Re-analyze"
                        : "Upload Resume (AI)"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appTheme.indigo_A700,
                      side: BorderSide(color: appTheme.indigo_A700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.h)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildCertificationsSection(BuildContext context, UserModel user) {
    final certifications = user.certifications ?? [];
    if (certifications.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProfileSectionTitle(title: "Certifications & Awards"),
        SizedBox(height: 12.h),
        ...certifications.map((cert) => Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color: appTheme.white_A700_01,
                borderRadius: BorderRadius.circular(16.h),
                border: Border.all(color: appTheme.gray_100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.card_membership,
                        color: Colors.amber, size: 20.h),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cert['name'] ?? 'Certification',
                            style: TextStyleHelper.instance.body14Bold),
                        Text("${cert['issuer'] ?? ''} • ${cert['date'] ?? ''}",
                            style: TextStyleHelper.instance.body12Medium
                                .copyWith(color: appTheme.gray_500)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildReviewCard(dynamic review) {
    Color getTagColor(String tag) {
      if (tag.toLowerCase().contains('quality')) return Colors.green;
      if (tag.toLowerCase().contains('communication')) return Colors.blue;
      if (tag.toLowerCase().contains('time')) return Colors.orange;
      return appTheme.indigo_A700;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.gray_200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: CustomImageView(
                      imagePath: 'assets/icons/star.svg',
                      height: 16.h,
                      width: 16.h,
                      color: index < review.score
                          ? Colors.amber
                          : appTheme.gray_300,
                    ),
                  );
                }),
              ),
              Text(
                "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                style: TextStyleHelper.instance.body12Medium
                    .copyWith(color: appTheme.gray_500),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            review.review,
            style: TextStyleHelper.instance.body14Medium
                .copyWith(color: appTheme.gray_900, height: 1.5),
          ),
          if (review.tags.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: (review.tags as List).map((tag) {
                final tagStr = tag.toString();
                final color = getTagColor(tagStr);
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Text(
                    tagStr,
                    style: TextStyleHelper.instance.body10Bold
                        .copyWith(color: color),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  final String title;

  const _ProfileSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyleHelper.instance.body18Bold.copyWith(
        color: appTheme.gray_900,
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _BadgeIcon({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.h),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyleHelper.instance.body10Bold.copyWith(
            color: appTheme.gray_600,
          ),
        ),
      ],
    );
  }
}

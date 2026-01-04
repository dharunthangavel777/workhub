import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';
import '../../widgets/shared/custom_icon_button.dart';
import '../../widgets/shared/custom_search_view.dart';
import './widgets/company_recommendation_widget.dart';
import './widgets/job_card_widget.dart';
import './widgets/home_carousel_widget.dart';
import 'saved_jobs_screen.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/models/job_post_model.dart';
import '../../../data/models/project_post_model.dart';
import '../shared/job_details_screen.dart';
import '../../widgets/shared/animated_profile_header_delegate.dart';
import './widgets/ai_match_button.dart';

class JobSearchDashboardScreen extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();

  JobSearchDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final activeMode = user?.activeMode ?? 'job';

    final allPosts = activeMode == 'job'
        ? jobProvider.jobPosts
            .where((p) => p.status != 'filled' && p.status != 'closed')
            .toList()
        : jobProvider.projectPosts
            .where((p) => p.status != 'filled' && p.status != 'closed')
            .toList();

    // Split into Recent and Recommended
    final recentPosts = allPosts.take(3).toList();
    final recommendedPosts =
        allPosts.length > 3 ? allPosts.skip(3).toList() : allPosts;

    // Extract unique companies for recommendation
    final companies = _extractCompanies(allPosts);

    return Scaffold(
      backgroundColor: appTheme.white_A700_01,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: AnimatedProfileHeaderDelegate(
              userName: user?.displayName ?? "Guest",
              welcomeMessage: "Welcome,",
              profileImage: user?.photoURL ?? ImageConstant.imgImage4,
              switchValue: activeMode == 'freelancer',
              firstLabel: "Job",
              secondLabel: "Freelancer",
              backgroundColor: appTheme.white_A700_01,
              onSwitchChanged: (value) async {
                final newMode = value ? 'freelancer' : 'job';
                await authProvider.switchWorkerMode(newMode);
                if (context.mounted) {
                  context.read<JobProvider>().updateMode(newMode);
                }
              },
              onProfileTap: () {},
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                  left: 24.h, right: 24.h, top: 0, bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(context),
                  SizedBox(height: 16.h),
                  const HomeCarouselWidget(),
                  SizedBox(height: 24.h),
                  if (recentPosts.isNotEmpty) ...[
                    _buildRecentlyPostedSection(context, recentPosts),
                    SizedBox(height: 16.h),
                  ],
                  if (companies.isNotEmpty) ...[
                    _buildRecommendedCompaniesSection(context, companies),
                    SizedBox(height: 16.h),
                  ],
                  if (recommendedPosts.isNotEmpty) ...[
                    _buildRecommendedJobsSection(context, recommendedPosts),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractCompanies(List<dynamic> posts) {
    final Map<String, Map<String, dynamic>> companies = {};
    for (var post in posts) {
      final name = post is JobPostModel
          ? post.companyName
          : (post as ProjectPostModel).companyName ?? "Freelance";
      final logo = post is JobPostModel
          ? post.companyLogo
          : (post as ProjectPostModel).companyLogo;
      final location = post is JobPostModel
          ? post.jobLocation
          : (post as ProjectPostModel).projectLocation;

      if (!companies.containsKey(name)) {
        companies[name] = {
          'name': name,
          'logo': logo ?? '',
          'location': location,
          'isVerified': true,
          'count': 1,
        };
      } else {
        companies[name]!['count'] = (companies[name]!['count'] as int) + 1;
      }
    }
    return companies.values.take(15).toList();
  }

  Widget _buildSearchSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomSearchView(
            controller: searchController,
            hintText: "Search jobs, titles",
            prefixIcon: ImageConstant.imgSearch,
            // backgroundColor: appTheme.gray_50,
            borderColor: appTheme.gray_400,
            onChanged: (value) {
              // Handle search filtering logic here if needed
            },
          ),
        ),
        SizedBox(width: 12.w),
        AIModeButton(
          onTap: () {
            // Handle AI Match logic
          },
        ),
      ],
    );
  }

  Widget _buildRecentlyPostedSection(
      BuildContext context, List<dynamic> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recently Posted",
              style: TextStyleHelper.instance.headline24Bold.copyWith(
                fontSize: 22.fSize,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SavedJobsScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: appTheme.indigo_A700.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16.h),
                ),
                child: Row(
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgNavSaved,
                      height: 14.h,
                      width: 14.h,
                      color: appTheme.indigo_A700,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "Saved Jobs",
                      style:
                          TextStyleHelper.instance.body12MediumPoppins.copyWith(
                        color: appTheme.indigo_A700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        ...posts
            .map((post) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: post is JobPostModel
                      ? JobCardWidget.fromJobPost(post,
                          onTap: () => _showJobDetails(context, post))
                      : JobCardWidget.fromProjectPost(post as ProjectPostModel,
                          onTap: () => _showJobDetails(context, post)),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildRecommendedCompaniesSection(
      BuildContext context, List<Map<String, dynamic>> companies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recommended for you",
          style: TextStyleHelper.instance.headline24Bold.copyWith(
            fontSize: 22.fSize,
          ),
        ),
        SizedBox(height: 20.h),
        Container(
          height: 190.h,
          child: ListView.separated(
            padding: EdgeInsets.only(left: 4.w, right: 16.w),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return CompanyRecommendationWidget(
                companyName: company['name'],
                logoPath: company['logo'],
                isVerified: company['isVerified'],
                location: company['location'],
                openJobsCount: company['count'],
                onTap: () {
                  // Handle company tap
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedJobsSection(
      BuildContext context, List<dynamic> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recommended for you",
          style: TextStyleHelper.instance.headline24Bold.copyWith(
            fontSize: 22.fSize,
          ),
        ),
        SizedBox(height: 24.h),
        ...posts
            .map((post) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: post is JobPostModel
                      ? JobCardWidget.fromJobPost(post,
                          onTap: () => _showJobDetails(context, post))
                      : JobCardWidget.fromProjectPost(post as ProjectPostModel,
                          onTap: () => _showJobDetails(context, post)),
                ))
            .toList(),
      ],
    );
  }

  void _showJobDetails(BuildContext context, dynamic post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailsScreen(post: post)),
    );
  }
}

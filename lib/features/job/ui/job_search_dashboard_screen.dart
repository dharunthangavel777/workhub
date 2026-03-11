import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/core/widgets/animated_profile_header_delegate.dart';
import 'package:work_hub/features/job/ui/job_details_screen.dart';
import 'package:work_hub/features/job/ui/widgets/job_card.dart';
import 'package:work_hub/core/shared_widgets/universal_skeleton.dart';
import './widgets/company_recommendation_widget.dart';
import 'saved_jobs_screen.dart';
import 'package:work_hub/features/job/ui/search_screen.dart';
import 'package:work_hub/features/job/logic/job_controller.dart';
import 'package:work_hub/features/job/domain/models/job.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';

class JobSearchDashboardScreen extends StatefulWidget {
  const JobSearchDashboardScreen({super.key});

  @override
  State<JobSearchDashboardScreen> createState() =>
      _JobSearchDashboardScreenState();
}

class _JobSearchDashboardScreenState extends State<JobSearchDashboardScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pagination Optimization
  final int _batchSize = 5;
  int _displayedCount = 5;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      _onSearchChanged(searchController.text);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    final threshold = pos.maxScrollExtent * 0.8;

    if (pos.pixels >= threshold && !_isLoadingMore) {
      _loadMoreItems();
    }

    // Prefetch logic: If we are past 50% of the current list, prefetch next batch images
    if (pos.pixels >= pos.maxScrollExtent * 0.5) {
      _prefetchNextBatch();
    }
  }

  void _prefetchNextBatch() {
    final provider = context.read<JobProvider>();
    final List<Job> sourcePosts = provider.activeMode == 'job'
        ? provider.jobPosts
        : provider.projectPosts;

    // Prefetch next 5 items beyond current displayed count
    final nextItems = sourcePosts
        .skip(_displayedCount)
        .take(5)
        .where((p) => p.companyLogo != null || p.ownerPhoto != null);

    for (var item in nextItems) {
      final imageUrl = item.companyLogo ?? item.ownerPhoto;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        precacheImage(NetworkImage(imageUrl), context);
      }
    }
  }

  void _onSearchChanged(String value) {
    context.read<JobProvider>().updateSearchQuery(value);
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate small delay for smooth UX or real network fetch
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _displayedCount += _batchSize;
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var horizontalPadding = EdgeInsets.symmetric(horizontal: 16.h);

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      body: Consumer<JobProvider>(
        builder: (context, provider, _) {
          // 1. Centralized Filtering Logic (O(N))
          final activeMode = provider.activeMode;
          // Both are List<Job> now
          final allFilteredPosts = activeMode == 'job'
              ? provider.filteredJobPosts
              : provider.filteredProjectPosts;

          // 2. Derived Lists
          final recentPosts = allFilteredPosts.take(3).toList();
          final companies = _extractCompanies(allFilteredPosts);

          // Pagination Logic for Recommended Posts
          final allRecommended = allFilteredPosts.length > 3
              ? allFilteredPosts.skip(3).toList()
              : [];

          // Safe clamping to avoid RangeError
          final currentDisplayCount =
              _displayedCount.clamp(0, allRecommended.length);
          final recommendedPosts =
              allRecommended.take(currentDisplayCount).toList();
          final hasMore = currentDisplayCount < allRecommended.length;

          return CustomScrollView(
            controller: _scrollController,
            cacheExtent: 1500.0,
            slivers: [
              // 1. Header
              Selector<
                  AuthProvider,
                  ({
                    String name,
                    String? photo,
                    double completion,
                    String mode
                  })>(
                selector: (_, auth) => (
                  name: auth.userModel?.displayName ?? "Guest",
                  photo: auth.userModel?.photoURL,
                  completion:
                      (auth.userModel?.profileCompletion ?? 0).toDouble(),
                  mode: auth.userModel?.activeMode ?? 'job'
                ),
                builder: (context, data, child) {
                  return SliverPersistentHeader(
                    pinned: true,
                    delegate: AnimatedProfileHeaderDelegate(
                      userName: data.name,
                      welcomeMessage: "Welcome,",
                      profileImage: data.photo ?? ImageConstant.imgImage4,
                      switchValue: data.mode == 'freelancer',
                      firstLabel: "Job",
                      secondLabel: "Freelancer",
                      backgroundColor: CustomColors.primaryBlue,
                      profileCompletion: data.completion,
                      onSwitchChanged: (value) async {
                        final newMode = value ? 'freelancer' : 'job';
                        await context
                            .read<AuthProvider>()
                            .switchWorkerMode(newMode);
                        if (context.mounted) {
                          context.read<JobProvider>().updateMode(newMode);
                        }
                      },
                      onProfileTap: () {},
                      searchController: searchController,
                      onSearchTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchScreen(
                                    initialQuery: searchController.text,
                                  )),
                        );
                      },
                    ),
                  );
                },
              ),



              // Loading State Shimmers
              if (provider.isLoading && allFilteredPosts.isEmpty)
                SliverPadding(
                  padding: horizontalPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => UniversalSkeleton.card(),
                      childCount: 3,
                    ),
                  ),
                ),

              // 3. Recently Posted Section
              if (recentPosts.isNotEmpty) ...[
                SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: horizontalPadding,
                        child: _buildSectionHeader(context, "Recently Posted",
                            showSaved: true),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverPadding(
                      padding: horizontalPadding,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = recentPosts[index];
                            final isJob = post.postType == 'job';
                            final user =
                                context.watch<AuthProvider>().userModel;
                            final isBookmarked = isJob
                                ? (user?.savedJobIds.contains(post.id) ?? false)
                                : (user?.savedProjectIds.contains(post.id) ??
                                    false);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: RepaintBoundary(
                                child: isJob
                                    ? JobCard.fromJobPost(post).copyWith(
                                        isBookmarked: isBookmarked,
                                        onTap: () =>
                                            _showJobDetails(context, post),
                                        onBookmarkToggle: () => _toggleBookmark(
                                            context, post, isBookmarked),
                                      )
                                    : JobCard.fromProjectPost(post).copyWith(
                                        isBookmarked: isBookmarked,
                                        onTap: () =>
                                            _showJobDetails(context, post),
                                        onBookmarkToggle: () => _toggleBookmark(
                                            context, post, isBookmarked),
                                      ),
                              ),
                            );
                          },
                          childCount: recentPosts.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // 4. Recommended Companies
              if (companies.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child:
                        _buildRecommendedCompaniesSection(context, companies),
                  ),
                ),

              // 5. Recommended Jobs Section
              if (recommendedPosts.isNotEmpty) ...[
                SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: horizontalPadding,
                        child: Text(
                          "Recommended for you",
                          style: TextStyleHelper.instance.headline22Bold,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverPadding(
                      padding: horizontalPadding,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = recommendedPosts[index];
                            final isJob = post.postType == 'job';
                            final user =
                                context.watch<AuthProvider>().userModel;
                            final isBookmarked = isJob
                                ? (user?.savedJobIds.contains(post.id) ?? false)
                                : (user?.savedProjectIds.contains(post.id) ??
                                    false);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: RepaintBoundary(
                                child: isJob
                                    ? JobCard.fromJobPost(post).copyWith(
                                        isBookmarked: isBookmarked,
                                        onTap: () =>
                                            _showJobDetails(context, post),
                                        onBookmarkToggle: () => _toggleBookmark(
                                            context, post, isBookmarked),
                                      )
                                    : JobCard.fromProjectPost(post).copyWith(
                                        isBookmarked: isBookmarked,
                                        onTap: () =>
                                            _showJobDetails(context, post),
                                        onBookmarkToggle: () => _toggleBookmark(
                                            context, post, isBookmarked),
                                      ),
                              ),
                            );
                          },
                          childCount: recommendedPosts.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Pagination Loader
              if (hasMore || _isLoadingMore)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: appTheme.indigo_A700,
                      ),
                    ),
                  ),
                ),

              // 6. Not Found Fallback
              if (!provider.isLoading && allFilteredPosts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomImageView(
                            imagePath: ImageConstant.imgSearch,
                            height: 100.h,
                            color: appTheme.gray_300,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            "Not Found",
                            style: TextStyleHelper.instance.body18Bold
                                .copyWith(color: appTheme.gray_900),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "No ${activeMode == 'job' ? 'jobs' : 'freelance posts'} available right now.",
                            textAlign: TextAlign.center,
                            style: TextStyleHelper.instance.body14Medium
                                .copyWith(color: appTheme.gray_500),
                          ),
                          SizedBox(height: 24.h),
                          TextButton(
                            onPressed: () async {
                              final newMode =
                                  activeMode == 'job' ? 'freelancer' : 'job';
                              await context
                                  .read<AuthProvider>()
                                  .switchWorkerMode(newMode);
                              if (context.mounted) {
                                context.read<JobProvider>().updateMode(newMode);
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: appTheme.indigo_A700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.h)),
                            ),
                            child: Text(
                              "Go to ${activeMode == 'job' ? 'Freelance Hub' : 'Job Hub'}",
                              style: TextStyleHelper.instance.body14Bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Bottom Padding
              SliverToBoxAdapter(child: SizedBox(height: 120.h)),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _extractCompanies(List<Job> posts) {
    final Map<String, Map<String, dynamic>> companies = {};
    for (var post in posts) {
      final isJob = post.postType == 'job';
      final name = post.companyName ??
          (isJob ? "Unknown" : "Freelance"); // Unify handling
      final logo = post.companyLogo;
      final location = post.location;

      if (!companies.containsKey(name)) {
        companies[name] = {
          'name': name,
          'logo': logo ?? '',
          'location': location,
          'isVerified': post.isVerified,
          'count': 1,
        };
      } else {
        companies[name]!['count'] = (companies[name]!['count'] as int) + 1;
      }
    }
    return companies.values.take(15).toList();
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {bool showSaved = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyleHelper.instance.headline22Bold,
        ),
        if (showSaved)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SavedJobsScreen()),
              );
            },
            child: Row(
              children: [
                Text(
                  "Favorites",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appTheme.indigo_A700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: appTheme.indigo_A700,
                  size: 14,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendedCompaniesSection(
      BuildContext context, List<Map<String, dynamic>> companies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          child: Text(
            "Our Top Companies",
            style: TextStyleHelper.instance.headline22Bold,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 190.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
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

  void _showJobDetails(BuildContext context, Job post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailsScreen(post: post)),
    );
  }

  void _toggleBookmark(BuildContext context, Job post, bool isBookmarked) {
    final auth = context.read<AuthProvider>();
    if (auth.userModel == null) return;

    context.read<JobProvider>().toggleSaveOpportunity(
          userId: auth.userModel!.uid,
          opportunityId: post.id,
          type: post.postType,
          isSaving: !isBookmarked,
        );
  }
}

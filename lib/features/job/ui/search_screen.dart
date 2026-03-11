import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/job/logic/job_controller.dart';
import 'package:work_hub/features/job/domain/models/job.dart';
import 'package:work_hub/features/job/ui/widgets/job_card.dart';
import 'package:work_hub/features/job/ui/job_details_screen.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/core/widgets/animated_typing_search_view.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ""});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  String _searchQuery = "";
  String _filterType = "All"; // All, Jobs, Projects

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchQuery = widget.initialQuery.toLowerCase();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: appTheme.indigo_A700, size: 20.h),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Search",
          style: GoogleFonts.poppins(
            color: appTheme.indigo_A700,
            fontSize: 18.fSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: AnimatedTypingSearchView(
        controller: _searchController,
        onChanged: (val) {
          // Handled by controller listener
        },
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ["All", "Jobs", "Projects"];
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterType == f;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(f,
                  style: GoogleFonts.poppins(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : appTheme.gray_600)),
              selected: isSelected,
              selectedColor: appTheme.indigo_A700,
              backgroundColor: appTheme.gray_100,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _filterType = f;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<JobProvider>(
      builder: (context, provider, child) {
        final jobPosts = provider.jobPosts;
        final projectPosts = provider.projectPosts;

        List<Job> allPosts = [];
        if (_filterType == "All" || _filterType == "Jobs") {
          allPosts.addAll(jobPosts);
        }
        if (_filterType == "All" || _filterType == "Projects") {
          allPosts.addAll(projectPosts);
        }

        final filteredPosts = allPosts.where((p) {
          final title = p.title.toLowerCase();
          final company = (p.companyName ?? "Unknown").toLowerCase();
          final location = p.location.toLowerCase();
          final skills = p.requiredSkills.map((s) => s.toLowerCase()).join(" ");

          return p.status != 'filled' &&
              p.status != 'closed' &&
              (_searchQuery.isEmpty ||
                  title.contains(_searchQuery) ||
                  company.contains(_searchQuery) ||
                  location.contains(_searchQuery) ||
                  skills.contains(_searchQuery));
        }).toList();

        if (filteredPosts.isEmpty) {
          return Center(
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
                  "No Results Found",
                  style: TextStyleHelper.instance.body18Bold
                      .copyWith(color: appTheme.gray_900),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Try adjusting your search or filters.",
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body14Medium
                      .copyWith(color: appTheme.gray_500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.h),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            final isJob = post.postType == 'job';
            final user = context.watch<AuthProvider>().userModel;
            final isBookmarked = isJob
                ? (user?.savedJobIds.contains(post.id) ?? false)
                : (user?.savedProjectIds.contains(post.id) ?? false);

            final jobCard = isJob
                ? JobCard.fromJobPost(post)
                : JobCard.fromProjectPost(post);

            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: jobCard.copyWith(
                isBookmarked: isBookmarked,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => JobDetailsScreen(post: post)),
                  );
                },
                onBookmarkToggle: () {
                  if (user == null) return;
                  context.read<JobProvider>().toggleSaveOpportunity(
                        userId: user.uid,
                        opportunityId: post.id,
                        type: post.postType,
                        isSaving: !isBookmarked,
                      );
                },
              ),
            );
          },
        );
      },
    );
  }
}




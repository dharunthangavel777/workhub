import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import '../../auth/ui/unified_login_screen.dart';
import '../../freelance/ui/worker_projects_screen.dart';
import '../../job/ui/reels/reels_tab_container.dart';
import '../../job/ui/job_search_dashboard_screen.dart';
import '../../ai/ui/ai_matchmaking_screen.dart';
import '../../../core/widgets/custom_bottom_bar.dart';
import '../../profile/ui/profile_screen.dart';

class WorkerNavigation extends StatefulWidget {
  const WorkerNavigation({super.key});

  @override
  State<WorkerNavigation> createState() => _WorkerNavigationState();
}

class _WorkerNavigationState extends State<WorkerNavigation>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _hideController;

  @override
  void initState() {
    super.initState();
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _hideController.forward(); // Initially visible
  }

  @override
  void dispose() {
    _hideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const JobSearchDashboardScreen(),
      const WorkerProjectsScreen(),
      ReelsTabContainer(isActive: _selectedIndex == 2),
      const AIMatchmakingScreen(),
      const ProfileScreen(),
    ];

    final userMode =
        context.watch<AuthProvider>().userModel?.activeMode ?? 'job';
    final isFreelancer = userMode == 'freelancer';

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (_selectedIndex != 0) return true; // Only apply to Home screen

              if (notification.direction == ScrollDirection.reverse) {
                if (!_hideController.isAnimating &&
                    _hideController.value == 1.0) {
                  _hideController.reverse();
                }
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_hideController.isAnimating &&
                    _hideController.value == 0.0) {
                  _hideController.forward();
                }
              }
              return true;
            },
            child: RepaintBoundary(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RepaintBoundary(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _hideController,
                  curve: Curves.easeInOutCubic,
                )),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomBottomBar(
                      selectedIndex: _selectedIndex,
                      onChanged: (index) {
                        final auth = context.read<AuthProvider>();
                        if (auth.isGuest && index != 0) {
                          _showGuestLoginPrompt(context);
                          return;
                        }
                        setState(() {
                          _selectedIndex = index;
                        });
                        // Always show bar when switching tabs
                        if (_hideController.value < 1.0) {
                          _hideController.forward();
                        }
                      },
                      bottomBarItemList: [
                        CustomBottomBarItem(
                          icon: ImageConstant.imgNavHome,
                          title: 'Home',
                          routeName: '',
                        ),
                        CustomBottomBarItem(
                          icon: ImageConstant.imgNavJobs,
                          title: isFreelancer ? 'Projects' : 'Jobs',
                          routeName: '',
                        ),
                        CustomBottomBarItem(
                          icon: ImageConstant.imgNavGigfeed,
                          title: 'Reels',
                          routeName: '',
                        ),
                        CustomBottomBarItem(
                          icon: 'assets/images/img_nav_ai.svg',
                          title: 'AI',
                          routeName: '',
                        ),
                        CustomBottomBarItem(
                          icon: ImageConstant.imgNavProfile,
                          title: 'Profile',
                          routeName: '',
                        ),
                      ],
                    ),
                    // Floating Button Overlay
                    Positioned(
                      bottom: 30.h,
                      child: GestureDetector(
                        onTap: () {
                          final auth = context.read<AuthProvider>();
                          if (auth.isGuest) {
                            _showGuestLoginPrompt(context);
                          } else {
                            setState(() {
                              _selectedIndex = 2;
                            });
                            if (_hideController.value < 1.0) {
                              _hideController.forward();
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(4.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Container(
                            height: 54.h,
                            width: 54.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedIndex == 2
                                  ? appTheme.indigo_A700
                                  : Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: CustomImageView(
                              imagePath: ImageConstant.imgNavGigfeed,
                              height: 24.h,
                              width: 24.h,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuestLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text(
          "Personalized Access",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Login to access your projects, profile, and personalized dashboard.",
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Maybe Later", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Login Now",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

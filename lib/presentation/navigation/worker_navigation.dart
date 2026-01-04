import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../logic/providers/auth_provider.dart';
import '../screens/auth/unified_login_screen.dart';
import '../screens/worker/worker_projects_screen.dart';
import '../screens/worker/reels/reels_tab_container.dart';
import '../screens/worker/job_search_dashboard_screen.dart';
import '../widgets/shared/custom_bottom_bar.dart';
import '../../core/utils/image_constant.dart';
import '../screens/profile/profile_screen.dart';

class WorkerNavigation extends StatefulWidget {
  const WorkerNavigation({super.key});

  @override
  State<WorkerNavigation> createState() => _WorkerNavigationState();
}

class _WorkerNavigationState extends State<WorkerNavigation> {
  int _selectedIndex = 0;
  bool _isBottomBarVisible = true;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      JobSearchDashboardScreen(),
      const WorkerProjectsScreen(),
      ReelsTabContainer(isActive: _selectedIndex == 2),
      const ProfileScreen(),
    ];

    final userMode =
        context.watch<AuthProvider>().userModel?.activeMode ?? 'job';
    final isFreelancer = userMode == 'freelancer';

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isBottomBarVisible)
              setState(() => _isBottomBarVisible = false);
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isBottomBarVisible)
              setState(() => _isBottomBarVisible = true);
          }
          return true;
        },
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isBottomBarVisible ? 84.h : 0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: CustomBottomBar(
            selectedIndex: _selectedIndex,
            onChanged: (index) {
              final auth = context.read<AuthProvider>();
              if (auth.isGuest && index != 0) {
                _showGuestLoginPrompt(context);
                return;
              }
              setState(() => _selectedIndex = index);
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
                icon: ImageConstant.imgNavProfile,
                title: 'Profile',
                routeName: '',
              ),
            ],
          ),
        ),
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
            child:
                const Text("Login Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

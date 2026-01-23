import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import '../screens/owner/owner_home.dart';
import '../screens/owner/manage_jobs_screen.dart';
import '../screens/profile/profile_screen.dart';

class BusinessOwnerNavigation extends StatefulWidget {
  const BusinessOwnerNavigation({super.key});

  @override
  State<BusinessOwnerNavigation> createState() =>
      _BusinessOwnerNavigationState();
}

class _BusinessOwnerNavigationState extends State<BusinessOwnerNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OwnerHome(),
    const ManageJobsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<JobProvider>().listenToProjects(user.uid, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.listCheck),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.building),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

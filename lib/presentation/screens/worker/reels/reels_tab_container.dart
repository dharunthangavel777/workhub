import 'package:flutter/material.dart';
import 'reels_feed_view.dart';
import 'reels_upload_view.dart';
import 'reels_profile_view.dart';

class ReelsTabContainer extends StatefulWidget {
  final bool isActive;

  const ReelsTabContainer({super.key, this.isActive = false});

  @override
  State<ReelsTabContainer> createState() => _ReelsTabContainerState();
}

class _ReelsTabContainerState extends State<ReelsTabContainer> {
  int _currentView = 0; // 0: Reels (Feed), 1: Upload, 2: My Reels (Profile)

  void _setView(int index) {
    setState(() => _currentView = index);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentView,
              children: [
                ReelsFeedView(isActive: widget.isActive),
                ReelsUploadView(
                    onUploadComplete: () => _setView(2)), // Go back to My Reels
                ReelsProfileView(onUploadRequested: () => _setView(1)),
              ],
            ),
            // Sub-navigation overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNavItem("Reels", 0),
                  const SizedBox(width: 40),
                  _buildNavItem("My Reels", 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, int index) {
    final isSelected = _currentView == index;
    return GestureDetector(
      onTap: () => _setView(index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}

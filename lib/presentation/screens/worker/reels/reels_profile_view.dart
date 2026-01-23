import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/data/models/reel_model.dart';
import 'package:work_hub/logic/providers/reel_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';

class ReelsProfileView extends StatefulWidget {
  final VoidCallback onUploadRequested;
  const ReelsProfileView({super.key, required this.onUploadRequested});

  @override
  State<ReelsProfileView> createState() => _ReelsProfileViewState();
}

class _ReelsProfileViewState extends State<ReelsProfileView> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reelProvider = context.watch<ReelProvider>();

    if (auth.userModel == null) return const SizedBox();

    final myReels = reelProvider.reels
        .where((r) => r.userId == auth.userModel!.uid)
        .toList();

    if (myReels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("You haven't uploaded any reels yet.",
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onUploadRequested,
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Upload Reel"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 80, 10, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 0.6,
      ),
      itemCount: myReels.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: widget.onUploadRequested,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white10,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text("Add Reel",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          );
        }
        final reel = myReels[index - 1];
        return GestureDetector(
          onTap: () => _viewReel(context, myReels, index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white10,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ideally show a thumbnail here, but using player for now
                  // ReelPlayer is heavy for grid, but let's see.
                  // In a real app we'd use a cached thumbnail from Supabase.
                  const Center(
                      child: Icon(Icons.play_circle_outline,
                          color: Colors.white54)),
                  Positioned(
                    bottom: 5,
                    left: 5,
                    child: Row(
                      children: [
                        const Icon(Icons.favorite,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text("${reel.likesCount}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _viewReel(BuildContext context, List<ReelModel> reels, int index) {
    // Show in a simpler fullscreen viewer or just push the feed starting at this index
    // For now, let's just show a simple snackbar or maybe we can improve this later.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Viewing specific reel is coming soon!")),
    );
  }
}

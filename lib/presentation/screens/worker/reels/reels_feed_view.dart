import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../logic/providers/reel_provider.dart';
import '../../../../logic/providers/auth_provider.dart';
import '../../../../core/utils/image_utils.dart';
import 'reel_player.dart';

class ReelsFeedView extends StatefulWidget {
  final bool isActive;

  const ReelsFeedView({super.key, this.isActive = false});

  @override
  State<ReelsFeedView> createState() => _ReelsFeedViewState();
}

class _ReelsFeedViewState extends State<ReelsFeedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelProvider>().fetchReels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reelProvider = context.watch<ReelProvider>();
    final authProvider = context.watch<AuthProvider>();
    final reels = reelProvider.reels;

    if (reelProvider.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (reels.isEmpty) {
      return const Center(
        child: Text("No reels yet. Be the first to upload!",
            style: TextStyle(color: Colors.white)),
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final reel = reels[index];
        final isLiked = reel.likedBy.contains(authProvider.userModel?.uid);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Video Player
            ReelPlayer(
              videoUrl: reel.videoUrl,
              autoPlay: index == 0,
              isActive: widget.isActive,
            ),

            // Interactions & Info Overlay
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Caption & User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: ImageUtils.getImageProvider(
                                  reel.userPhotoUrl),
                              backgroundColor: Colors.white24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "@${reel.username ?? 'user'}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          reel.caption,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Actions Column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Like
                      _buildActionItem(
                        icon: isLiked
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        color: isLiked ? Colors.red : Colors.white,
                        label: "${reel.likesCount}",
                        onTap: () {
                          if (authProvider.userModel != null) {
                            reelProvider.toggleLike(
                                reel.id, authProvider.userModel!);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      // Comment
                      _buildActionItem(
                        icon: FontAwesomeIcons.comment,
                        color: Colors.white,
                        label: "Comments",
                        onTap: () => _showCommentsBottomSheet(context, reel.id),
                      ),
                      const SizedBox(height: 20),
                      // More Options
                      _buildActionItem(
                        icon: FontAwesomeIcons.ellipsisVertical,
                        color: Colors.white,
                        label: "Options",
                        onTap: () => _showReelOptions(context, reel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReelOptions(BuildContext context, dynamic reel) {
    final authProvider = context.read<AuthProvider>();
    final isOwner = reel.userId == authProvider.userModel?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Delete Reel",
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, reel.id);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title:
                    const Text("Share", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title:
                    const Text("Info", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String reelId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text("Delete Reel?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this reel?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<ReelProvider>().deleteReel(reelId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reel deleted")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, String reelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text("Comments",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white)),
            const Divider(color: Colors.white12),
            Expanded(
              child: StreamBuilder(
                stream: context.read<ReelProvider>().getComments(reelId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return const Center(
                        child: Text("No comments yet.",
                            style: TextStyle(color: Colors.white54)));
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              ImageUtils.getImageProvider(comment.userPhotoUrl),
                          backgroundColor: Colors.white12,
                        ),
                        title: Text(comment.username ?? 'user',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        subtitle: Text(comment.text,
                            style: const TextStyle(color: Colors.white70)),
                      );
                    },
                  );
                },
              ),
            ),
            _buildCommentInput(context, reelId),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, String reelId) {
    final controller = TextEditingController();
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        left: 15,
        right: 15,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Add a comment...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final auth = context.read<AuthProvider>();
                if (auth.userModel != null) {
                  context
                      .read<ReelProvider>()
                      .addComment(reelId, controller.text, auth.userModel!);
                  controller.clear();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_export.dart';
import 'package:work_hub/logic/providers/reel_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/utils/image_utils.dart';
import 'reel_player.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import 'package:work_hub/theme/theme_helper.dart';
import 'package:work_hub/logic/providers/ad_provider.dart';
import 'ad_reel_item.dart';

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
      context.read<AdProvider>().fetchActiveAds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reelProvider = context.watch<ReelProvider>();
    final authProvider = context.watch<AuthProvider>();
    final reels = reelProvider.reels;

    if (reelProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: appTheme.indigo_A700),
      );
    }

    if (reels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgSearch,
              height: 64.h,
              color: appTheme.gray_300,
            ),
            SizedBox(height: 16.h),
            Text(
              "No reels yet. Be the first to upload!",
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray_500),
            ),
          ],
        ),
      );
    }

    final activeAds = context.watch<AdProvider>().activeAds;
    print("ReelsFeedView: Active Ads Count: ${activeAds.length}");
    const int adFrequency = 2; // Ad after every 2 reels for testing

    // Calculate total items (reels + ads)
    // If 5 reels, 0 ads -> total 5
    // If 6 reels, 1 ad -> total 7. (Reel 0-4, Ad, Reel 5)

    int totalItems = reels.length;
    if (activeAds.isNotEmpty) {
      totalItems += (reels.length ~/ adFrequency);
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Check if this index should be an ad
        // Index 5 (6th item) should be ad if frequency is 5
        // 0,1,2,3,4 -> Reel
        // 5 -> Ad
        // 6 -> Reel
        final bool isAdSlot =
            activeAds.isNotEmpty && (index + 1) % (adFrequency + 1) == 0;

        if (isAdSlot) {
          // Calculate which ad to show (wrap around if fewer ads than slots)
          final int adIndex = ((index + 1) ~/ (adFrequency + 1)) - 1;
          final ad = activeAds[adIndex % activeAds.length];
          return AdReelItem(
              ad: ad,
              isActive:
                  widget.isActive); // Pass simplified isActive or manage focus
        }

        // Calculate mapped reel index
        final int reelIndex =
            index - (activeAds.isEmpty ? 0 : (index ~/ (adFrequency + 1)));

        // Safety check
        if (reelIndex >= reels.length) return const SizedBox();

        final reel = reels[reelIndex];
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

            // Gradient Overlay for readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),

            // Interactions & Info Overlay
            Positioned(
              bottom: 30.h,
              left: 16.w,
              right: 16.w,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Caption & User Info inside a glass-style card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.h),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16.h,
                                backgroundImage: ImageUtils.getImageProvider(
                                    reel.userPhotoUrl),
                                backgroundColor: appTheme.white_A700_01,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                "@${reel.username ?? 'user'}",
                                style: TextStyleHelper.instance.body14Bold
                                    .copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            reel.caption,
                            style: TextStyleHelper.instance.body12Medium
                                .copyWith(color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Actions Column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionItem(
                        icon: isLiked
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        color: isLiked ? Colors.red : appTheme.gray_900,
                        label: "${reel.likesCount}",
                        onTap: () {
                          if (authProvider.userModel != null) {
                            reelProvider.toggleLike(
                                reel.id, authProvider.userModel!);
                          }
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildActionItem(
                        icon: FontAwesomeIcons.comment,
                        color: appTheme.gray_900,
                        label: "Chat",
                        onTap: () => _showCommentsBottomSheet(context, reel.id),
                      ),
                      SizedBox(height: 16.h),
                      _buildActionItem(
                        icon: FontAwesomeIcons.ellipsisVertical,
                        color: appTheme.gray_900,
                        label: "More",
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
          Container(
            height: 44.h,
            width: 44.h,
            decoration: BoxDecoration(
              color: appTheme.white_A700_01.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Icon(icon, color: color, size: 20.h),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyleHelper.instance.body14Medium.copyWith(
              color: Colors.white,
              shadows: [const Shadow(blurRadius: 4, color: Colors.black45)],
            ),
          ),
        ],
      ),
    );
  }

  void _showReelOptions(BuildContext context, dynamic reel) {
    final authProvider = context.read<AuthProvider>();
    final isOwner = reel.userId == authProvider.userModel?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.white_A700_01,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title:
                      Text("Delete Reel", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, reel.id);
                  },
                ),
              ListTile(
                leading: Icon(Icons.share_outlined, color: appTheme.gray_900),
                title:
                    Text("Share", style: TextStyleHelper.instance.body14Medium),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: appTheme.gray_900),
                title:
                    Text("Info", style: TextStyleHelper.instance.body14Medium),
                onTap: () => Navigator.pop(context),
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
        backgroundColor: appTheme.white_A700_01,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h)),
        title: Text("Delete Reel?", style: TextStyleHelper.instance.body16Bold),
        content: Text("Are you sure you want to delete this reel?",
            style: TextStyleHelper.instance.body14Medium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: appTheme.gray_500)),
          ),
          TextButton(
            onPressed: () {
              context.read<ReelProvider>().deleteReel(reelId);
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
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
        decoration: BoxDecoration(
          color: appTheme.white_A700_01,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              height: 4.h,
              width: 40.w,
              decoration: BoxDecoration(
                color: appTheme.gray_200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text("Comments", style: TextStyleHelper.instance.body16Bold),
            Divider(color: appTheme.gray_100),
            Expanded(
              child: StreamBuilder(
                stream: context.read<ReelProvider>().getComments(reelId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return Center(
                        child: Text("No comments yet.",
                            style: TextStyle(color: appTheme.gray_400)));
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              ImageUtils.getImageProvider(comment.userPhotoUrl),
                        ),
                        title: Text(comment.username ?? 'user',
                            style: TextStyleHelper.instance.body14Bold),
                        subtitle: Text(comment.text,
                            style: TextStyleHelper.instance.body12Medium
                                .copyWith(color: appTheme.gray_600)),
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
        left: 20.w,
        right: 20.w,
        top: 12.h,
      ),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        border: Border(top: BorderSide(color: appTheme.gray_100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: appTheme.gray_50,
                borderRadius: BorderRadius.circular(24.h),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Add a comment...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.send, color: appTheme.indigo_A700),
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

import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/reel/logic/reel_controller.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/core/utils/image_utils.dart';
import 'reel_player.dart';
import 'package:work_hub/features/job/logic/ad_controller.dart';
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
    return Selector3<
        ReelProvider,
        AuthProvider,
        AdProvider,
        ({
          List<dynamic> reels,
          List<dynamic> ads,
          String? userId,
          bool isLoading
        })>(
      selector: (_, rp, ap, adp) => (
        reels: rp.reels,
        ads: adp.activeAds,
        userId: ap.userModel?.uid,
        isLoading: rp.isLoading,
      ),
      builder: (context, data, child) {
        if (data.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: appTheme.indigo_A700),
          );
        }

        if (data.reels.isEmpty) {
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

        const int adFrequency = 2;
        final activeAds = data.ads;
        final reels = data.reels;

        int totalItems = reels.length;
        if (activeAds.isNotEmpty) {
          totalItems += (reels.length ~/ adFrequency);
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: totalItems,
          itemBuilder: (context, index) {
            final bool isAdSlot =
                activeAds.isNotEmpty && (index + 1) % (adFrequency + 1) == 0;

            if (isAdSlot) {
              final int adIndex = ((index + 1) ~/ (adFrequency + 1)) - 1;
              final ad = activeAds[adIndex % activeAds.length];
              return AdReelItem(ad: ad, isActive: widget.isActive);
            }

            final int reelIndex =
                index - (activeAds.isEmpty ? 0 : (index ~/ (adFrequency + 1)));

            if (reelIndex >= reels.length) return const SizedBox();

            final reel = reels[reelIndex];

            return RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ReelPlayer(
                    videoUrl: reel.videoUrl,
                    autoPlay: index == 0,
                    isActive: widget.isActive,
                  ),
                  const Positioned.fill(
                    child: RepaintBoundary(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black12,
                              Colors.transparent,
                              Colors.black45,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 110.h,
                    left: 16.w,
                    right: 16.w,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: RepaintBoundary(
                            child: Container(
                              padding: EdgeInsets.all(12.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20.h),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16.h,
                                        backgroundImage:
                                            ImageUtils.getImageProvider(
                                                reel.userPhotoUrl),
                                        backgroundColor: appTheme.white_A700_01,
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        "@${reel.username ?? 'user'}",
                                        style: TextStyleHelper
                                            .instance.body14Bold
                                            .copyWith(color: Colors.white),
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
                        ),
                        SizedBox(width: 12.w),
                        Selector<ReelProvider,
                            ({bool isLiked, int likesCount})>(
                          selector: (_, rp) => (
                            isLiked: reel.likedBy.contains(data.userId),
                            likesCount: reel.likesCount,
                          ),
                          builder: (context, interactionData, _) {
                            return RepaintBoundary(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildActionItem(
                                    icon: interactionData.isLiked
                                        ? FontAwesomeIcons.solidHeart
                                        : FontAwesomeIcons.heart,
                                    color: interactionData.isLiked
                                        ? Colors.red
                                        : appTheme.gray_900,
                                    label: "${interactionData.likesCount}",
                                    onTap: () {
                                      if (data.userId != null) {
                                        context.read<ReelProvider>().toggleLike(
                                            reel.id,
                                            context
                                                .read<AuthProvider>()
                                                .userModel!);
                                      }
                                    },
                                  ),
                                  SizedBox(height: 16.h),
                                  _buildActionItem(
                                    icon: FontAwesomeIcons.comment,
                                    color: appTheme.gray_900,
                                    label: "Chat",
                                    onTap: () => _showCommentsBottomSheet(
                                        context, reel.id),
                                  ),
                                  SizedBox(height: 16.h),
                                  _buildActionItem(
                                    icon: FontAwesomeIcons.ellipsisVertical,
                                    color: appTheme.gray_900,
                                    label: "More",
                                    onTap: () =>
                                        _showReelOptions(context, reel),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
              color: appTheme.white_A700_01.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Delete Reel",
                      style: TextStyle(color: Colors.red)),
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
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
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




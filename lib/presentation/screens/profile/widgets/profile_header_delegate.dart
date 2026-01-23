import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import 'package:work_hub/theme/theme_helper.dart';
import 'package:work_hub/utils/size_utils.dart';
import '../../../../config/app_export.dart';
import 'package:work_hub/utils/image_utils.dart';
import 'package:work_hub/data/models/user_model.dart';

class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onBackTap;
  final VoidCallback? onEditImage;
  final double profileCompletion;

  ProfileHeaderDelegate({
    required this.user,
    required this.isCurrentUser,
    this.onSettingsTap,
    this.onBackTap,
    this.onEditImage,
    this.profileCompletion = 0,
  });

  @override
  double get maxExtent => 340.h;

  @override
  // Increased the fixed height after animation by adding 20.h to the standard toolbar height
  double get minExtent =>
      kToolbarHeight +
      MediaQueryData.fromView(PlatformDispatcher.instance.views.first)
          .padding
          .top +
      20.h;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double rawProgress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    final double smoothProgress = Curves.easeInOut.transform(rawProgress);

    final double expandedOpacity =
        Interval(0.0, 0.3, curve: Curves.easeIn).transform(1.0 - rawProgress);

    final double collapsedOpacity =
        Interval(0.7, 1.0, curve: Curves.easeIn).transform(rawProgress);

    final size = MediaQuery.of(context).size;
    final paddingTop = MediaQuery.of(context).padding.top;
    // The actual height of the "bar" area in the collapsed state
    final collapsedBarHeight = minExtent - paddingTop;

    // --- Avatar Math ---
    final double avatarExpandedSize = 100.h;
    final double avatarCollapsedSize =
        40.h; // Slightly larger collapsed avatar for the taller bar
    final double avatarSize =
        lerpDouble(avatarExpandedSize, avatarCollapsedSize, smoothProgress)!;

    final double avatarLeftStart = (size.width - avatarExpandedSize) / 2;
    final double avatarLeftEnd = isCurrentUser ? 16.w : 56.w;
    final double avatarLeft =
        lerpDouble(avatarLeftStart, avatarLeftEnd, smoothProgress)!;

    // Avatar Y Position: Centered perfectly in the NEW taller minExtent area
    final double avatarTopStart = 120.h;
    final double avatarTopEnd =
        paddingTop + (collapsedBarHeight - avatarCollapsedSize) / 2;
    final double avatarTop =
        lerpDouble(avatarTopStart, avatarTopEnd, smoothProgress)!;

    return Container(
      color: appTheme.white_A700_01,
      child: Stack(
        children: [
          // 1. Banner with Parallax
          Positioned(
            top: -shrinkOffset * 0.3,
            left: 0,
            right: 0,
            height: 180.h,
            child: Opacity(
              opacity: (1.0 - rawProgress * 1.5).clamp(0.0, 1.0),
              child: _buildBanner(),
            ),
          ),

          // 2. Background Blur Overlay
          Positioned.fill(
            child: Opacity(
              opacity: rawProgress,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 10 * rawProgress, sigmaY: 10 * rawProgress),
                  child: Container(
                      color: appTheme.white_A700_01.withOpacity(0.85)),
                ),
              ),
            ),
          ),

          // 3. Expanded Details
          if (expandedOpacity > 0)
            Positioned(
              top: avatarTopStart +
                  avatarExpandedSize +
                  16.h -
                  (shrinkOffset * 0.2),
              left: 0,
              right: 0,
              child: Opacity(
                opacity: expandedOpacity,
                child: Column(
                  children: [
                    _buildMainTitle(textAlign: TextAlign.center),
                    SizedBox(height: 4.h),
                    _buildSubtitle(textAlign: TextAlign.center),
                    if (user.location != null) _buildLocation(),
                    SizedBox(height: 20.h),
                    _buildStatsRow(),
                  ],
                ),
              ),
            ),

          // 4. Collapsed Details (Vertically centered in the new taller bar)
          if (collapsedOpacity > 0)
            Positioned(
              top: paddingTop,
              bottom: 0,
              left: avatarLeftEnd + avatarCollapsedSize + 12.w,
              right: 60.w,
              child: Opacity(
                opacity: collapsedOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMainTitle(fontSize: 18.fSize, isShort: true),
                    _buildSubtitle(fontSize: 12.fSize),
                  ],
                ),
              ),
            ),

          // 5. The Dynamic Avatar
          Positioned(
            top: avatarTop,
            left: avatarLeft,
            child: _buildAvatar(avatarSize, smoothProgress),
          ),

          // 6. Navigation Controls (Centered vertically in the new taller bar)
          _buildTopActions(
              context, paddingTop, collapsedBarHeight, rawProgress),

          // 7. Bottom Border
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: rawProgress > 0.9 ? 1.0 : 0.0,
              child:
                  Divider(height: 1, color: appTheme.gray_200, thickness: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.indigo_A700.withOpacity(0.1),
        image: user.bannerImage != null
            ? DecorationImage(
                image: ImageUtils.getImageProvider(user.bannerImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.1),
              Colors.transparent,
              Colors.black.withOpacity(0.05)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double size, double progress) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(lerpDouble(4.h, 1.5.h, progress)!),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: appTheme.white_A700_01,
            boxShadow: [
              if (progress < 0.5)
                BoxShadow(
                  color: Colors.black.withOpacity(0.1 * (1.0 - progress)),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: (user.role != UserRole.businessOwner)
              ? CircularProgressIndicator(
                  value: profileCompletion / 100,
                  strokeWidth: lerpDouble(3, 1.5, progress)!,
                  backgroundColor: appTheme.gray_100,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(appTheme.indigo_A700),
                )
              : null,
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(lerpDouble(6.h, 3.h, progress)!),
            child: CircleAvatar(
              backgroundColor: appTheme.gray_100,
              backgroundImage: ImageUtils.getImageProvider(user.photoURL),
              child: user.photoURL == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : "U",
                      style: TextStyle(
                        fontSize: lerpDouble(32, 16, progress),
                        fontWeight: FontWeight.bold,
                        color: appTheme.indigo_A700,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (isCurrentUser && progress < 0.2)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditImage,
              child: Container(
                padding: EdgeInsets.all(6.h),
                decoration: BoxDecoration(
                  color: appTheme.indigo_A700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt, size: 12.h, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainTitle(
      {TextAlign? textAlign, double? fontSize, bool isShort = false}) {
    String text =
        (user.role == UserRole.businessOwner && user.companyName != null)
            ? user.companyName!
            : user.displayName;

    return Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyleHelper.instance.headline22Bold.copyWith(
        color: appTheme.gray_900,
        fontSize: fontSize ?? 24.fSize,
      ),
    );
  }

  Widget _buildSubtitle({TextAlign? textAlign, double? fontSize}) {
    String text = (user.role == UserRole.businessOwner)
        ? (user.managerName ?? "Hiring Manager")
        : (user.jobCategory ?? "@${user.username ?? 'user'}");
    return Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyleHelper.instance.body14Medium.copyWith(
        color: appTheme.gray_600,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildLocation() {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 14.h, color: appTheme.gray_400),
          SizedBox(width: 4.w),
          Text(
            user.location!,
            style: TextStyleHelper.instance.body12Medium
                .copyWith(color: appTheme.gray_500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (user.role == UserRole.businessOwner) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Followers", "1.2k"),
          _buildStatDivider(),
          _buildStatItem("Projects", "48"),
          _buildStatDivider(),
          _buildStatItem("Rating", "4.9"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: TextStyleHelper.instance.body10Medium
                .copyWith(color: appTheme.gray_900)),
        Text(label,
            style: TextStyleHelper.instance.body10Medium
                .copyWith(color: appTheme.gray_500)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 20.h, width: 1, color: appTheme.gray_200);
  }

  Widget _buildTopActions(BuildContext context, double paddingTop,
      double barHeight, double progress) {
    // Calculate the Y center for buttons within the new bar height
    final double buttonTop = paddingTop + (barHeight - 40.h) / 2;

    return Stack(
      children: [
        if (!isCurrentUser)
          Positioned(
            top: buttonTop,
            left: 8.w,
            child: _buildActionBtn(
              icon: Icons.arrow_back_ios_new,
              onTap: onBackTap ?? () => Navigator.pop(context),
              progress: progress,
            ),
          ),
        if (isCurrentUser)
          Positioned(
            top: buttonTop,
            right: 8.w,
            child: _buildActionBtn(
              icon: Icons.settings_outlined,
              onTap: onSettingsTap ??
                  () => Navigator.pushNamed(context, '/settings'),
              progress: progress,
            ),
          ),
      ],
    );
  }

  Widget _buildActionBtn(
      {required IconData icon,
      required VoidCallback onTap,
      required double progress}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        width: 40.h,
        decoration: BoxDecoration(
          color: progress > 0.5
              ? Colors.transparent
              : Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20.h,
          color: appTheme.gray_900,
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/app_export.dart';
import 'custom_image_view.dart';

class AnimatedProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String userName;
  final String welcomeMessage;
  final String? profileImage;
  final bool switchValue;
  final String firstLabel;
  final String secondLabel;
  final Function(bool)? onSwitchChanged;
  final VoidCallback? onProfileTap;
  final Color? backgroundColor;
  final double profileCompletion;

  AnimatedProfileHeaderDelegate({
    required this.userName,
    required this.welcomeMessage,
    this.profileImage,
    required this.switchValue,
    required this.firstLabel,
    required this.secondLabel,
    this.onSwitchChanged,
    this.onProfileTap,
    this.backgroundColor,
    this.profileCompletion = 0,
  });

  @override
  double get maxExtent => 160.h; // Reduced from 195.h for compactness

  @override
  double get minExtent => 120.h; // Increased back to 120.h as requested

  @override
  bool shouldRebuild(covariant AnimatedProfileHeaderDelegate oldDelegate) {
    return oldDelegate.userName != userName ||
        oldDelegate.welcomeMessage != welcomeMessage ||
        oldDelegate.profileImage != profileImage ||
        oldDelegate.switchValue != switchValue ||
        oldDelegate.profileCompletion != profileCompletion ||
        oldDelegate.backgroundColor != backgroundColor;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double progress = shrinkOffset / (maxExtent - minExtent);
    final double clampedProgress = progress.clamp(0.0, 1.0);

    // Interpolated values - Reduced sizes
    final double avatarSize = lerpDouble(56.h, 42.h, clampedProgress)!;
    final double avatarRadius = avatarSize / 2;
    final double horizontalPadding = lerpDouble(24.w, 20.w, clampedProgress)!;
    final double topPadding =
        lerpDouble(12.h, 10.h, clampedProgress)!; // Reduced padding
    final double welcomeOpacity =
        (1.0 - (clampedProgress * 3.5)).clamp(0.0, 1.0);
    final double userNameSize =
        lerpDouble(18.fSize, 16.fSize, clampedProgress)!; // Reduced text size

    // Smoother elevation appearance
    final double elevationProgress =
        (clampedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final Color bgColor = Color.lerp(
      Colors.transparent,
      backgroundColor ?? Colors.white,
      clampedProgress,
    )!;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: elevationProgress > 0.1
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05 * elevationProgress),
                    blurRadius: 4.0, // Constant blur for performance
                    offset: const Offset(0, 2), // Constant offset
                  )
                ]
              : null,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: topPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (profileCompletion > 0)
                              SizedBox(
                                width: avatarSize + 8.h,
                                height: avatarSize + 8.h,
                                child: CircularProgressIndicator(
                                  value: profileCompletion / 100,
                                  strokeWidth: 3,
                                  backgroundColor:
                                      CustomColors.primaryBlue.withOpacity(0.1),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    CustomColors.primaryBlue,
                                  ),
                                ),
                              ),
                            CustomImageView(
                              imagePath:
                                  profileImage ?? ImageConstant.imgImage4,
                              height: avatarSize,
                              width: avatarSize,
                              radius: BorderRadius.circular(avatarRadius),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (welcomeOpacity > 0)
                              Opacity(
                                opacity: welcomeOpacity,
                                child: Text(
                                  welcomeMessage,
                                  style: TextStyleHelper
                                      .instance.body14RegularPoppins
                                      .copyWith(
                                    fontSize: 14.fSize,
                                  ),
                                ),
                              ),
                            Text(
                              userName,
                              style: TextStyleHelper
                                  .instance.title20SemiBoldPoppins
                                  .copyWith(
                                fontSize: userNameSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                _buildSwitch(clampedProgress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(double progress) {
    final double scale = lerpDouble(1.0, 0.95, progress)!;
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: EdgeInsets.all(4.h),
        decoration: BoxDecoration(
          color: appTheme.gray_50,
          borderRadius: BorderRadius.circular(30.h),
          border: Border.all(color: appTheme.gray_100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSwitchItem(firstLabel, !switchValue, progress),
            _buildSwitchItem(secondLabel, switchValue, progress),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String label, bool isSelected, double progress) {
    final double horizontalPadding = lerpDouble(16.w, 14.w, progress)!;
    final double verticalPadding = lerpDouble(10.h, 8.h, progress)!;
    final double fontSize = lerpDouble(12.fSize, 11.5.fSize, progress)!;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          onSwitchChanged?.call(!switchValue);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: isSelected ? appTheme.indigo_A700 : Colors.transparent,
          borderRadius: BorderRadius.circular(24.h),
          border: isSelected
              ? Border.all(
                  color: appTheme.indigo_A700.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : appTheme.gray_400,
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

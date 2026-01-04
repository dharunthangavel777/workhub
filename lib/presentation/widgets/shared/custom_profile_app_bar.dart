import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import 'custom_image_view.dart';

class CustomProfileAppBar extends StatelessWidget {
  final String userName;
  final String welcomeMessage;
  final String? profileImage;
  final bool switchValue;
  final String firstLabel;
  final String secondLabel;
  final Function(bool)? onSwitchChanged;
  final Color? backgroundColor;

  final VoidCallback? onProfileTap;

  CustomProfileAppBar({
    required this.userName,
    required this.welcomeMessage,
    this.profileImage,
    required this.switchValue,
    required this.firstLabel,
    required this.secondLabel,
    this.onSwitchChanged,
    this.backgroundColor,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      color: backgroundColor ?? Colors.white,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: CustomImageView(
                      imagePath: profileImage ?? ImageConstant.imgImage4,
                      height: 58.h,
                      width: 53.w,
                      radius: BorderRadius.circular(29.h),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          welcomeMessage,
                          style: TextStyleHelper.instance.body14RegularPoppins
                              .copyWith(fontSize: 16.fSize),
                        ),
                        Text(
                          userName,
                          style: TextStyleHelper.instance.title20SemiBoldPoppins
                              .copyWith(fontSize: 23.fSize),
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
            _buildSwitch(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitchItem(firstLabel, !switchValue),
          _buildSwitchItem(secondLabel, switchValue),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          onSwitchChanged?.call(!switchValue);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? appTheme.indigo_A700 : Colors.transparent,
          borderRadius: BorderRadius.circular(16.h),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : appTheme.gray_400,
            fontSize: 12.fSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

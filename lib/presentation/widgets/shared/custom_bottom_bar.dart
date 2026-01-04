import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import 'custom_image_view.dart';

class CustomBottomBar extends StatelessWidget {
  final List<CustomBottomBarItem> bottomBarItemList;
  final int selectedIndex;
  final Function(int)? onChanged;

  CustomBottomBar({
    required this.bottomBarItemList,
    required this.selectedIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.h),
          topRight: Radius.circular(24.h),
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.black_900.withOpacity(0.05),
            blurRadius: 10.h,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          bottomBarItemList.length,
          (index) {
            final item = bottomBarItemList[index];
            final isSelected = selectedIndex == index;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged?.call(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomImageView(
                        imagePath: item.icon,
                        height: 24.h,
                        width: 24.h,
                        color: isSelected
                            ? appTheme.indigo_A700
                            : appTheme.gray_400,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected
                              ? appTheme.indigo_A700
                              : appTheme.gray_400,
                          fontSize: 12.fSize,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CustomBottomBarItem {
  final String icon;
  final String title;
  final String routeName;

  CustomBottomBarItem({
    required this.icon,
    required this.title,
    required this.routeName,
  });
}

import 'package:work_hub/core/config/app_export.dart';

class CustomBottomBar extends StatelessWidget {
  final List<CustomBottomBarItem> bottomBarItemList;
  final int selectedIndex;
  final Function(int)? onChanged;

  const CustomBottomBar({
    super.key,
    required this.bottomBarItemList,
    required this.selectedIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: 84.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.h),
            topRight: Radius.circular(24.h),
          ),
          boxShadow: [
            BoxShadow(
              color: appTheme.black_900.withValues(alpha: 0.05),
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

              // Center Item (Index 2) - Prominent Style
              if (index == 2) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged?.call(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -12.h), // Lift up slightly
                          child: Container(
                            height: 50.h,
                            width: 50.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: appTheme.indigo_A700,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: appTheme.indigo_A700
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomImageView(
                              imagePath: item.icon,
                              height: 24.h,
                              width: 24.h,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, -6.h), // Adjust text position
                          child: Text(
                            item.title, // "Reels"
                            style: TextStyle(
                              color: isSelected
                                  ? appTheme.indigo_A700
                                  : appTheme.gray_400,
                              fontSize: 12.fSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Other Items - Standard Style
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged?.call(index),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
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




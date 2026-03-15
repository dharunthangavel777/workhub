import 'package:qwok/core/config/app_export.dart';

class CustomIconButton extends StatelessWidget {
  final String iconPath;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onPressed;

  const CustomIconButton({
    super.key,
    required this.iconPath,
    this.backgroundColor,
    this.margin,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.h),
          ),
          fixedSize: Size(52.h, 52.h),
          elevation: 2,
          shadowColor: appTheme.black900.withValues(alpha: 0.1),
        ),
        icon: CustomImageView(
          imagePath: iconPath,
          height: 24.h,
          width: 24.h,
          color: appTheme.indigoA700,
        ),
      ),
    );
  }
}




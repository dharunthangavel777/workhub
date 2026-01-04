import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import 'custom_image_view.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final String? rightIcon;

  CustomButton({
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? appTheme.indigo_A700,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.h),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.h),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.fSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (rightIcon != null) ...[
              SizedBox(width: 8.h),
              CustomImageView(
                imagePath: rightIcon!,
                height: 18.h,
                width: 18.h,
                color: textColor ?? Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

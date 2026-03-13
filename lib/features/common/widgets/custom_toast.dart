import 'package:work_hub/core/config/app_export.dart';

enum ToastType { success, warning, loading, info, error }

class CustomToast extends StatelessWidget {
  final ToastType type;
  final String title;
  final String? message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const CustomToast({
    super.key,
    required this.type,
    required this.title,
    this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 80.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.h),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              SizedBox(width: 12.w),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyleHelper.instance.body14Medium.copyWith(
                        color: CustomColors.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        message!,
                        style: TextStyleHelper.instance.body12Medium.copyWith(
                          color: appTheme.gray_600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              if (type == ToastType.error && onRetry != null)
                IconButton(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh_rounded, 
                    color: Colors.red.shade400, 
                    size: 20.h
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close_rounded, 
                    color: appTheme.gray_400, 
                    size: 20.h
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case ToastType.success:
        iconData = Icons.check_circle_rounded;
        iconColor = Colors.green;
        break;
      case ToastType.warning:
        iconData = Icons.warning_rounded;
        iconColor = Colors.orange;
        break;
      case ToastType.loading:
        return SizedBox(
          height: 18.h,
          width: 18.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(CustomColors.primaryBlue),
          ),
        );
      case ToastType.info:
        iconData = Icons.info_rounded;
        iconColor = CustomColors.primaryBlue;
        break;
      case ToastType.error:
        iconData = Icons.error_rounded;
        iconColor = Colors.red;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 24.h,
    );
  }
}




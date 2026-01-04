import 'package:flutter/material.dart';
import '../../core/theme/custom_colors.dart';

enum ToastType { success, warning, loading, info, error }

class CustomToast extends StatelessWidget {
  final ToastType type;
  final String title;
  final String? message;

  const CustomToast({
    super.key,
    required this.type,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getBgColor().withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBgColor().withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                color: _getIconColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: CustomColors.darkText,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      message!,
                      style: TextStyle(
                        fontSize: 12,
                        color: CustomColors.darkText.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBgColor() {
    switch (type) {
      case ToastType.success:
        return const Color(0xFFE8F5E9); // Light Green
      case ToastType.warning:
        return const Color(0xFFFFF3E0); // Light Orange
      case ToastType.loading:
        return const Color(0xFFF5F5F5); // Light Grey
      case ToastType.info:
        return const Color(0xFFE3F2FD); // Light Blue
      case ToastType.error:
        return const Color(0xFFFFEBEE); // Light Red
    }
  }

  Color _getIconColor() {
    switch (type) {
      case ToastType.success:
        return Colors.green.shade600;
      case ToastType.warning:
        return Colors.orange.shade600;
      case ToastType.loading:
        return Colors.grey.shade600;
      case ToastType.info:
        return Colors.blue.shade600;
      case ToastType.error:
        return Colors.red.shade600;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.loading:
        return Icons.refresh; // Should rotate in a real imp, but static for now
      case ToastType.info:
        return Icons.info;
      case ToastType.error:
        return Icons.error;
    }
  }
}

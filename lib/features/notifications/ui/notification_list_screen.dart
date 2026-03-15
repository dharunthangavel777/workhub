import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qwok/core/config/app_export.dart';
import '../logic/notification_provider.dart';
import '../models/notification_model.dart';
import 'package:qwok/features/chat/ui/chat_list_screen.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: Text("Notifications", style: TextStyleHelper.instance.headline22Bold),
        backgroundColor: CustomColors.lightBg,
        elevation: 0,
        iconTheme: IconThemeData(color: appTheme.gray900),
        actions: [
          TextButton(
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
            child: Text("Mark all read", style: TextStyleHelper.instance.body14Bold.copyWith(color: appTheme.indigoA700)),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60.h, color: appTheme.gray400),
                  SizedBox(height: 16.h),
                  Text("No notifications yet", style: TextStyleHelper.instance.body16Bold.copyWith(color: appTheme.gray600)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _NotificationCard(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  String _formatRelativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 7) {
      return "\${time.day}/\${time.month}/\${time.year}";
    } else if (difference.inDays > 0) {
      return "\${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "\${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "\${difference.inMinutes}m ago";
    } else {
      return "just now";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.status != 'read';

    IconData getIcon() {
      switch (notification.category) {
        case 'chat_message': return Icons.chat_bubble_outline;
        case 'bid_approved': return Icons.check_circle_outline;
        case 'withdrawal_pending':
        case 'payout_initiated':
        case 'payout_settled': return Icons.account_balance_wallet_outlined;
        case 'dispute_raised': return Icons.warning_amber_rounded;
        default: return Icons.notifications_none;
      }
    }

    Color getIconColor() {
      switch (notification.category) {
        case 'chat_message': return Colors.blue;
        case 'bid_approved': return Colors.green;
        case 'withdrawal_pending':
        case 'payout_initiated':
        case 'payout_settled': return appTheme.indigoA700;
        case 'dispute_raised': return Colors.red;
        default: return appTheme.gray600;
      }
    }

    return GestureDetector(
      onTap: () {
        context.read<NotificationProvider>().markAsRead(notification.id);
        
        final category = notification.category;
        if (category == 'chat_message') {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen()));
        } else if (category == 'withdrawal_pending' || category == 'payout_initiated' || category == 'payout_settled') {
           Navigator.pushNamed(context, '/wallet');
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: isUnread ? appTheme.indigoA700.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(
            color: isUnread ? appTheme.indigoA700.withValues(alpha: 0.2) : appTheme.gray200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: getIconColor().withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(), color: getIconColor(), size: 24.h),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyleHelper.instance.body14Bold.copyWith(
                            color: isUnread ? appTheme.gray900 : appTheme.gray600,
                          ),
                        ),
                      ),
                      Text(
                        _formatRelativeTime(notification.createdAt),
                        style: TextStyleHelper.instance.body10Medium.copyWith(color: appTheme.gray500),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: TextStyleHelper.instance.body12Medium.copyWith(
                      color: appTheme.gray600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              SizedBox(width: 8.w),
              Container(
                width: 8.h,
                height: 8.h,
                margin: EdgeInsets.only(top: 8.h),
                decoration: BoxDecoration(
                  color: appTheme.indigoA700,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

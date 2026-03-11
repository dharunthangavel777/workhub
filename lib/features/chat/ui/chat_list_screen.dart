import 'package:provider/provider.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/features/chat/logic/chat_controller.dart';

import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<ChatProvider>().fetchChats(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().userModel;

    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// HEADER WITH BACK BUTTON
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Messages',
                    style: TextStyleHelper.instance.headline22Bold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            /// WHITE BODY
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: appTheme.white_A700_01,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: Selector<ChatProvider, List<dynamic>>(
                  selector: (_, provider) => provider.chats,
                  builder: (context, chats, _) {
                    if (chats.isEmpty) {
                      return Center(
                        child: Text(
                          "No conversations yet",
                          style: TextStyleHelper.instance.body14Medium
                              .copyWith(color: appTheme.gray_500),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.only(top: 16.h, bottom: 20.h),
                      cacheExtent: 1000,
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final otherUser =
                            "User ${chat.participants.firstWhere((id) => id != currentUser?.uid).substring(0, 4)}";

                        return RepaintBoundary(
                          child: ListTile(
                            leading: CustomImageView(
                              height: 48.h,
                              width: 48.h,
                              radius: BorderRadius.circular(24.h),
                              color: appTheme.indigo_A700,
                              imagePath: null,
                            ),
                            title: Text(
                              otherUser,
                              style:
                                  TextStyleHelper.instance.body16Bold.copyWith(
                                color: CustomColors.darkText,
                              ),
                            ),
                            subtitle: Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyleHelper.instance.body12Medium
                                  .copyWith(
                                color: (chat.unreadCounts[
                                                currentUser?.uid ?? ''] ??
                                            0) >
                                        0
                                    ? CustomColors.darkText
                                    : appTheme.gray_500,
                                fontWeight: (chat.unreadCounts[
                                                currentUser?.uid ?? ''] ??
                                            0) >
                                        0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTimestamp(chat.lastMessageTimestamp),
                                  style: TextStyleHelper.instance.body12Medium
                                      .copyWith(
                                    fontSize: 12,
                                    color: (chat.unreadCounts[
                                                    currentUser?.uid ?? ''] ??
                                                0) >
                                            0
                                        ? CustomColors.primaryBlue
                                        : appTheme.gray_400,
                                  ),
                                ),
                                if ((chat.unreadCounts[
                                            currentUser?.uid ?? ''] ??
                                        0) >
                                    0) ...[
                                  SizedBox(height: 4.h),
                                  Container(
                                    padding: EdgeInsets.all(6.h),
                                    decoration: const BoxDecoration(
                                      color: CustomColors.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      chat.unreadCounts[currentUser!.uid]!
                                          .toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.fSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              context.read<ChatProvider>().markAsRead(chat.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatRoomScreen(
                                    chatId: chat.id,
                                    otherUserName: otherUser,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}

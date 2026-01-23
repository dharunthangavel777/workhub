import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/logic/providers/chat_provider.dart';
import 'package:work_hub/theme/custom_colors.dart';
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
    final chatProvider = context.watch<ChatProvider>();
    final currentUser = context.read<AuthProvider>().userModel;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text("Messages"),
        elevation: 0,
        backgroundColor: CustomColors.lightBg,
      ),
      body: chatProvider.chats.isEmpty
          ? const Center(
              child: Text(
                "No conversations yet",
                style: TextStyle(color: CustomColors.textMuted),
              ),
            )
          : ListView.builder(
              itemCount: chatProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];
                // In a real app, we would fetch the other user's name from DB
                // For now, we'll use a placeholder
                final otherUser =
                    "User ${chat.participants.firstWhere((id) => id != currentUser?.uid).substring(0, 4)}";

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: CustomColors.primaryBlue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    otherUser,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CustomColors.darkText,
                    ),
                  ),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: CustomColors.textMuted),
                  ),
                  trailing: Text(
                    _formatTimestamp(chat.lastMessageTimestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CustomColors.textMuted,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        chatId: chat.id,
                        otherUserName: otherUser,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}

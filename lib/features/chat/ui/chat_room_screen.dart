import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/core/theme/custom_colors.dart';
import 'package:work_hub/features/chat/models/message.dart';
import 'package:work_hub/features/chat/logic/chat_controller.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final currentUser = context.read<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: CustomColors.lightCard,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatProvider.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  cacheExtent: 1000,
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.uid;

                    return RepaintBoundary(
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? CustomColors.primaryBlue
                                : CustomColors.lightCard,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe
                                  ? const Radius.circular(0)
                                  : const Radius.circular(16),
                              bottomLeft: isMe
                                  ? const Radius.circular(16)
                                  : const Radius.circular(0),
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color:
                                  isMe ? Colors.white : CustomColors.darkText,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CustomColors.lightCard,
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (_messageController.text.isNotEmpty &&
                          currentUser != null) {
                        await chatProvider.sendMessage(
                          widget.chatId,
                          currentUser.uid,
                          _messageController.text,
                        );
                        _messageController.clear();
                      }
                    },
                    icon:
                        const Icon(Icons.send, color: CustomColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}




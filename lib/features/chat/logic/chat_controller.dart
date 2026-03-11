import 'package:flutter/material.dart';
import 'package:work_hub/features/chat/models/message.dart';
import 'package:work_hub/features/chat/data/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository = ChatRepository();

  List<ChatModel> _chats = [];
  final bool _isLoading = false;
  String _currentUserId = '';

  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;

  int get totalUnreadCount {
    if (_currentUserId.isEmpty) return 0;
    int count = 0;
    for (var chat in _chats) {
      count += chat.unreadCounts[_currentUserId] ?? 0;
    }
    return count;
  }

  void fetchChats(String userId) {
    _currentUserId = userId;
    _repository.getChatList(userId).listen((chats) {
      _chats = chats;
      notifyListeners();
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _repository.getMessages(chatId);
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final message = MessageModel(
      id: '',
      senderId: senderId,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.sendMessage(chatId, message);
  }

  Future<String> startChat(String user1, String user2) async {
    return await _repository.getOrCreateChat(user1, user2);
  }

  Future<void> markAsRead(String chatId) async {
    if (_currentUserId.isNotEmpty) {
      await _repository.markAsRead(chatId, _currentUserId);
    }
  }
}

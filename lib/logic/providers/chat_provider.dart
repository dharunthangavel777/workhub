import 'package:flutter/material.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository = ChatRepository();

  List<ChatModel> _chats = [];
  final bool _isLoading = false;

  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;

  void fetchChats(String userId) {
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
}

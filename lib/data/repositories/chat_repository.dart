import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ChatModel>> getChatList(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatModel.fromMap(doc.id, doc.data());
          }).toList()..sort(
            (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
          );
        });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    final batch = _firestore.batch();

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(messageRef, message.toMap());

    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': message.text,
      'lastMessageTimestamp': message.timestamp,
    });

    await batch.commit();
  }

  Future<String> getOrCreateChat(String user1, String user2) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: user1)
        .get();

    for (final doc in snapshot.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(user2)) {
        return doc.id;
      }
    }

    final newChatRef = _firestore.collection('chats').doc();
    await newChatRef.set({
      'participants': [user1, user2],
      'lastMessage': '',
      'lastMessageTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
    return newChatRef.id;
  }
}

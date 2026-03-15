import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qwok/features/chat/models/message.dart';

import 'package:qwok/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';

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
      }).toList()
        ..sort(
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
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final participants =
        List<String>.from(chatDoc.data()?['participants'] ?? []);
    final recipientId = participants.firstWhere((id) => id != message.senderId,
        orElse: () => '');

    final batch = _firestore.batch();

    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(messageRef, message.toMap());

    Map<String, dynamic> updateData = {
      'lastMessage': message.text,
      'lastMessageTimestamp': message.timestamp,
    };

    if (recipientId.isNotEmpty) {
      updateData['unreadCounts.$recipientId'] = FieldValue.increment(1);
    }

    batch.update(_firestore.collection('chats').doc(chatId), updateData);

    await batch.commit();

    // Trigger Notification
    try {
      if (recipientId.isNotEmpty) {
        NotificationService().sendNotification(
          recipientId: recipientId,
          title: 'New Message',
          body: message.text,
          category: 'chat_message',
          data: {'chatId': chatId},
        );
      }
    } catch (e) {
      debugPrint("Chat Notification Error: $e");
    }
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts.$userId': 0,
    });
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

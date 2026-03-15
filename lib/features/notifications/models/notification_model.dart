import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String? senderId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? category;
  final String status; // 'pending', 'read', 'unread'
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    this.senderId,
    required this.title,
    required this.body,
    required this.data,
    this.category,
    required this.status,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: map['recipientId'] ?? '',
      senderId: map['senderId'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: map['data'] ?? {},
      category: map['category'],
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

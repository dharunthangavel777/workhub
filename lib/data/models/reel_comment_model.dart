import 'package:cloud_firestore/cloud_firestore.dart';

class ReelCommentModel {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String? username; // Denormalized
  final String? userPhotoUrl; // Denormalized

  ReelCommentModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.username,
    this.userPhotoUrl,
  });

  factory ReelCommentModel.fromMap(Map<String, dynamic> map, String id) {
    return ReelCommentModel(
      id: id,
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      username: map['username'],
      userPhotoUrl: map['userPhotoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'username': username,
      'userPhotoUrl': userPhotoUrl,
    };
  }
}

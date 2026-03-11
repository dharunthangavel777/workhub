import 'package:cloud_firestore/cloud_firestore.dart';

class ReelModel {
  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final String? username; // Denormalized for performance
  final String? userPhotoUrl; // Denormalized for performance

  ReelModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    this.likesCount = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.username,
    this.userPhotoUrl,
  });

  factory ReelModel.fromMap(Map<String, dynamic> map, String id) {
    return ReelModel(
      id: id,
      userId: map['userId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      caption: map['caption'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      username: map['username'],
      userPhotoUrl: map['userPhotoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'videoUrl': videoUrl,
      'caption': caption,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'username': username,
      'userPhotoUrl': userPhotoUrl,
    };
  }

  ReelModel copyWith({
    String? caption,
    int? likesCount,
    List<String>? likedBy,
    String? username,
    String? userPhotoUrl,
  }) {
    return ReelModel(
      id: id,
      userId: userId,
      videoUrl: videoUrl,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
    );
  }
}




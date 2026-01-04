import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String projectId;
  final String ratedBy; // userId who gave the rating
  final String ratedUser; // userId who received the rating
  final String raterRole; // 'owner' or 'worker'
  final double score; // 1-5
  final String review;
  final List<String> tags; // e.g., ['communication', 'quality', 'timeliness']
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.projectId,
    required this.ratedBy,
    required this.ratedUser,
    required this.raterRole,
    required this.score,
    required this.review,
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Rating.fromMap(String id, Map<String, dynamic> map) {
    return Rating(
      id: id,
      projectId: map['projectId'] ?? '',
      ratedBy: map['ratedBy'] ?? '',
      ratedUser: map['ratedUser'] ?? '',
      raterRole: map['raterRole'] ?? '',
      score: (map['score'] ?? 0.0).toDouble(),
      review: map['review'] ?? '',
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'ratedBy': ratedBy,
      'ratedUser': ratedUser,
      'raterRole': raterRole,
      'score': score,
      'review': review,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String ownerId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String ctaLabel;
  final String ctaLink;
  final String status; // pending, active, rejected, paused, completed
  final double totalBudget;
  final double remainingBudget;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final int views;
  final int clicks;
  final int likes;
  final DateTime createdAt;
  final String? rejectionReason;
  final String? username; // Denormalized for easy display
  final String? userPhotoUrl; // Denormalized for easy display

  AdModel({
    required this.id,
    required this.ownerId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.ctaLabel,
    required this.ctaLink,
    required this.status,
    required this.totalBudget,
    required this.remainingBudget,
    this.currency = 'INR',
    required this.startDate,
    required this.endDate,
    this.views = 0,
    this.clicks = 0,
    this.likes = 0,
    required this.createdAt,
    this.rejectionReason,
    this.username,
    this.userPhotoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'ctaLabel': ctaLabel,
      'ctaLink': ctaLink,
      'status': status,
      'budget': {
        'total': totalBudget,
        'remaining': remainingBudget,
        'currency': currency,
      },
      'duration': {
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
      },
      'metrics': {
        'views': views,
        'clicks': clicks,
        'likes': likes,
      },
      'createdAt': Timestamp.fromDate(createdAt),
      'rejectionReason': rejectionReason,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
    };
  }

  factory AdModel.fromMap(Map<String, dynamic> map) {
    // Handle nested maps safely
    final budgetMap = map['budget'] as Map<String, dynamic>? ?? {};
    final durationMap = map['duration'] as Map<String, dynamic>? ?? {};
    final metricsMap = map['metrics'] as Map<String, dynamic>? ?? {};

    return AdModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      caption: map['caption'] ?? '',
      ctaLabel: map['ctaLabel'] ?? 'Learn More',
      ctaLink: map['ctaLink'] ?? '',
      status: map['status'] ?? 'pending',
      totalBudget: (budgetMap['total'] ?? 0).toDouble(),
      remainingBudget: (budgetMap['remaining'] ?? 0).toDouble(),
      currency: budgetMap['currency'] ?? 'INR',
      startDate:
          (durationMap['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (durationMap['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
      views: metricsMap['views'] ?? 0,
      clicks: metricsMap['clicks'] ?? 0,
      likes: metricsMap['likes'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rejectionReason: map['rejectionReason'],
      username: map['username'],
      userPhotoUrl: map['userPhotoUrl'],
    );
  }
}

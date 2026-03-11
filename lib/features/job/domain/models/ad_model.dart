import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String ownerId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String ctaLabel;
  final String ctaLink;
  final String status;
  final double totalBudget;
  final double remainingBudget;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String username;
  final String userPhotoUrl;
  final int views;
  final int clicks;

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
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.username,
    required this.userPhotoUrl,
    this.views = 0,
    this.clicks = 0,
  });

  factory AdModel.fromMap(Map<String, dynamic> map) {
    return AdModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      caption: map['caption'] ?? '',
      ctaLabel: map['ctaLabel'] ?? '',
      ctaLink: map['ctaLink'] ?? '',
      status: map['status'] ?? 'pending',
      totalBudget: (map['totalBudget'] ?? 0).toDouble(),
      remainingBudget: (map['remainingBudget'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      views: map['views'] ?? 0,
      clicks: map['clicks'] ?? 0,
    );
  }

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
      'totalBudget': totalBudget,
      'remainingBudget': remainingBudget,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'views': views,
      'clicks': clicks,
    };
  }
}




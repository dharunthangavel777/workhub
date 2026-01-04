import 'package:cloud_firestore/cloud_firestore.dart';

class ContractTerms {
  final String id;
  final String projectId;
  final double agreedBudget;
  final DateTime startDate;
  final DateTime expectedCompletion;
  final String paymentType; // 'fixed' or 'hourly'
  final double platformFee; // percentage (e.g., 10.0 for 10%)
  final bool ownerAccepted;
  final bool workerAccepted;
  final DateTime? ownerAcceptedAt;
  final DateTime? workerAcceptedAt;
  final DateTime createdAt;
  final String? additionalTerms;

  ContractTerms({
    required this.id,
    required this.projectId,
    required this.agreedBudget,
    required this.startDate,
    required this.expectedCompletion,
    required this.paymentType,
    this.platformFee = 10.0,
    this.ownerAccepted = false,
    this.workerAccepted = false,
    this.ownerAcceptedAt,
    this.workerAcceptedAt,
    DateTime? createdAt,
    this.additionalTerms,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFullyAccepted => ownerAccepted && workerAccepted;

  factory ContractTerms.fromMap(String id, Map<String, dynamic> map) {
    return ContractTerms(
      id: id,
      projectId: map['projectId'] ?? '',
      agreedBudget: (map['agreedBudget'] ?? 0.0).toDouble(),
      startDate: _parseTimestamp(map['startDate']),
      expectedCompletion: _parseTimestamp(map['expectedCompletion']),
      paymentType: map['paymentType'] ?? 'fixed',
      platformFee: (map['platformFee'] ?? 10.0).toDouble(),
      ownerAccepted: map['ownerAccepted'] ?? false,
      workerAccepted: map['workerAccepted'] ?? false,
      ownerAcceptedAt: map['ownerAcceptedAt'] != null
          ? _parseTimestamp(map['ownerAcceptedAt'])
          : null,
      workerAcceptedAt: map['workerAcceptedAt'] != null
          ? _parseTimestamp(map['workerAcceptedAt'])
          : null,
      createdAt: _parseTimestamp(map['createdAt']),
      additionalTerms: map['additionalTerms'],
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
      'agreedBudget': agreedBudget,
      'startDate': Timestamp.fromDate(startDate),
      'expectedCompletion': Timestamp.fromDate(expectedCompletion),
      'paymentType': paymentType,
      'platformFee': platformFee,
      'ownerAccepted': ownerAccepted,
      'workerAccepted': workerAccepted,
      'ownerAcceptedAt':
          ownerAcceptedAt != null ? Timestamp.fromDate(ownerAcceptedAt!) : null,
      'workerAcceptedAt': workerAcceptedAt != null
          ? Timestamp.fromDate(workerAcceptedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'additionalTerms': additionalTerms,
    };
  }

  ContractTerms copyWith({
    double? agreedBudget,
    DateTime? startDate,
    DateTime? expectedCompletion,
    String? paymentType,
    double? platformFee,
    bool? ownerAccepted,
    bool? workerAccepted,
    DateTime? ownerAcceptedAt,
    DateTime? workerAcceptedAt,
    String? additionalTerms,
  }) {
    return ContractTerms(
      id: id,
      projectId: projectId,
      agreedBudget: agreedBudget ?? this.agreedBudget,
      startDate: startDate ?? this.startDate,
      expectedCompletion: expectedCompletion ?? this.expectedCompletion,
      paymentType: paymentType ?? this.paymentType,
      platformFee: platformFee ?? this.platformFee,
      ownerAccepted: ownerAccepted ?? this.ownerAccepted,
      workerAccepted: workerAccepted ?? this.workerAccepted,
      ownerAcceptedAt: ownerAcceptedAt ?? this.ownerAcceptedAt,
      workerAcceptedAt: workerAcceptedAt ?? this.workerAcceptedAt,
      createdAt: createdAt,
      additionalTerms: additionalTerms ?? this.additionalTerms,
    );
  }
}

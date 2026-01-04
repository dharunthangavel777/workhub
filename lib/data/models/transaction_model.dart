import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  escrowDeposit,
  milestonePayment,
  refund,
  platformFee,
  withdrawal,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class Transaction {
  final String id;
  final String projectId;
  final String userId; // who initiated the transaction
  final TransactionType type;
  final double amount;
  final String description;
  final String? relatedMilestoneId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final TransactionStatus status;

  Transaction({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.relatedMilestoneId,
    DateTime? createdAt,
    this.metadata,
    this.status = TransactionStatus.completed,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Transaction.fromMap(String id, Map<String, dynamic> map) {
    return Transaction(
      id: id,
      projectId: map['projectId'] ?? '',
      userId: map['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.escrowDeposit,
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      relatedMilestoneId: map['relatedMilestoneId'],
      createdAt: _parseTimestamp(map['createdAt']),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.completed,
      ),
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
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'relatedMilestoneId': relatedMilestoneId,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
      'status': status.name,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum DisputeStatus {
  open,
  underReview,
  resolved,
  closed,
}

enum DisputeOutcome {
  pending,
  fullRefund,
  partialPayment,
  fullPayment,
}

class DisputeInfo {
  final String id;
  final String projectId;
  final String raisedBy; // userId who raised the dispute
  final String raisedByRole; // 'owner' or 'worker'
  final String reason;
  final String description;
  final List<String> evidence; // URLs to uploaded files
  final DisputeStatus status;
  final DisputeOutcome outcome;
  final String? adminId; // Admin handling the dispute
  final String? adminDecision;
  final double? refundAmount;
  final double? paymentAmount;
  final DateTime raisedAt;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;

  DisputeInfo({
    required this.id,
    required this.projectId,
    required this.raisedBy,
    required this.raisedByRole,
    required this.reason,
    required this.description,
    this.evidence = const [],
    this.status = DisputeStatus.open,
    this.outcome = DisputeOutcome.pending,
    this.adminId,
    this.adminDecision,
    this.refundAmount,
    this.paymentAmount,
    DateTime? raisedAt,
    this.reviewedAt,
    this.resolvedAt,
  }) : raisedAt = raisedAt ?? DateTime.now();

  factory DisputeInfo.fromMap(String id, Map<String, dynamic> map) {
    return DisputeInfo(
      id: id,
      projectId: map['projectId'] ?? '',
      raisedBy: map['raisedBy'] ?? '',
      raisedByRole: map['raisedByRole'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      evidence:
          map['evidence'] != null ? List<String>.from(map['evidence']) : [],
      status: DisputeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DisputeStatus.open,
      ),
      outcome: DisputeOutcome.values.firstWhere(
        (e) => e.name == map['outcome'],
        orElse: () => DisputeOutcome.pending,
      ),
      adminId: map['adminId'],
      adminDecision: map['adminDecision'],
      refundAmount: (map['refundAmount'] as num?)?.toDouble(),
      paymentAmount: (map['paymentAmount'] as num?)?.toDouble(),
      raisedAt: _parseTimestamp(map['raisedAt']),
      reviewedAt:
          map['reviewedAt'] != null ? _parseTimestamp(map['reviewedAt']) : null,
      resolvedAt:
          map['resolvedAt'] != null ? _parseTimestamp(map['resolvedAt']) : null,
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
      'raisedBy': raisedBy,
      'raisedByRole': raisedByRole,
      'reason': reason,
      'description': description,
      'evidence': evidence,
      'status': status.name,
      'outcome': outcome.name,
      'adminId': adminId,
      'adminDecision': adminDecision,
      'refundAmount': refundAmount,
      'paymentAmount': paymentAmount,
      'raisedAt': Timestamp.fromDate(raisedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  DisputeInfo copyWith({
    DisputeStatus? status,
    DisputeOutcome? outcome,
    String? adminId,
    String? adminDecision,
    double? refundAmount,
    double? paymentAmount,
    DateTime? reviewedAt,
    DateTime? resolvedAt,
  }) {
    return DisputeInfo(
      id: id,
      projectId: projectId,
      raisedBy: raisedBy,
      raisedByRole: raisedByRole,
      reason: reason,
      description: description,
      evidence: evidence,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      adminId: adminId ?? this.adminId,
      adminDecision: adminDecision ?? this.adminDecision,
      refundAmount: refundAmount ?? this.refundAmount,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      raisedAt: raisedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}




import 'package:cloud_firestore/cloud_firestore.dart';

enum MilestoneStatus {
  pending,
  submitted,
  approved,
  revisionRequested,
}

class Milestone {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final double amount;
  final DateTime deadline;
  final MilestoneStatus status;
  final String? submissionNote;
  final List<String>? attachments;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? revisionNote;
  final DateTime createdAt;
  final bool workerAgreed;
  final DateTime? workerAgreedAt;

  Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.amount,
    required this.deadline,
    this.status = MilestoneStatus.pending,
    this.submissionNote,
    this.attachments,
    this.submittedAt,
    this.approvedAt,
    this.revisionNote,
    DateTime? createdAt,
    this.workerAgreed = false,
    this.workerAgreedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Milestone.fromMap(String id, Map<String, dynamic> map) {
    return Milestone(
      id: id,
      projectId: map['projectId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      deadline: _parseTimestamp(map['deadline']),
      status: MilestoneStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MilestoneStatus.pending,
      ),
      submissionNote: map['submissionNote'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      submittedAt: map['submittedAt'] != null
          ? _parseTimestamp(map['submittedAt'])
          : null,
      approvedAt:
          map['approvedAt'] != null ? _parseTimestamp(map['approvedAt']) : null,
      revisionNote: map['revisionNote'],
      createdAt: _parseTimestamp(map['createdAt']),
      workerAgreed: map['workerAgreed'] ?? false,
      workerAgreedAt: map['workerAgreedAt'] != null
          ? _parseTimestamp(map['workerAgreedAt'])
          : null,
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
      'title': title,
      'description': description,
      'amount': amount,
      'deadline': Timestamp.fromDate(deadline),
      'status': status.name,
      'submissionNote': submissionNote,
      'attachments': attachments,
      'submittedAt':
          submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'revisionNote': revisionNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'workerAgreed': workerAgreed,
      'workerAgreedAt':
          workerAgreedAt != null ? Timestamp.fromDate(workerAgreedAt!) : null,
    };
  }

  Milestone copyWith({
    String? title,
    String? description,
    double? amount,
    DateTime? deadline,
    MilestoneStatus? status,
    String? submissionNote,
    List<String>? attachments,
    DateTime? submittedAt,
    DateTime? approvedAt,
    String? revisionNote,
  }) {
    return Milestone(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      submissionNote: submissionNote ?? this.submissionNote,
      attachments: attachments ?? this.attachments,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      revisionNote: revisionNote ?? this.revisionNote,
      createdAt: createdAt,
    );
  }
}

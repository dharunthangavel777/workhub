import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String jobId;
  final String workerId;
  final String ownerId;
  final String title;
  final String description;
  final double progress; // 0.0 to 1.0
  final String
      status; // 'setup', 'active', 'completed', 'cancelled', 'disputed'
  final Map<String, dynamic>? tasks;
  final Map<String, dynamic>? payments;
  final int createdAt;
  final int? completedAt;
  final String? workerName;
  final double? budget;
  final double platformFee;
  final double netEarnings;
  final double escrowBalance;

  // NEW FIELDS for freelancer platform
  final String? projectType; // 'fixed' or 'hourly'
  final String? contractId; // Reference to contract terms
  final List<String>? milestoneIds; // References to milestones
  final String? disputeId; // Reference to active dispute
  final String? ownerRatingId; // Reference to owner's rating
  final String? workerRatingId; // Reference to worker's rating
  final int? startDate;
  final int? deadline;
  final double? hourlyRate; // For hourly projects
  final List<Map<String, dynamic>>? sharedFiles; // Metadata for shared assets
  final bool depositPaid;
  final String? termsAndConditions;
  final double? requiredDeposit;

  ProjectModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.ownerId,
    required this.title,
    required this.description,
    this.progress = 0.0,
    this.status = 'active',
    this.tasks,
    this.payments,
    required this.createdAt,
    this.completedAt,
    this.workerName,
    this.budget,
    this.platformFee = 0.0,
    this.netEarnings = 0.0,
    this.escrowBalance = 0.0,
    // New parameters
    this.projectType,
    this.contractId,
    this.milestoneIds,
    this.disputeId,
    this.ownerRatingId,
    this.workerRatingId,
    this.startDate,
    this.deadline,
    this.hourlyRate,
    this.sharedFiles,
    this.depositPaid = false,
    this.termsAndConditions,
    this.requiredDeposit,
  });

  factory ProjectModel.fromMap(String id, Map<String, dynamic> map) {
    return ProjectModel(
      id: id,
      jobId: map['jobId'] ?? '',
      workerId: map['workerId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      progress: (map['progress'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'active',
      tasks:
          map['tasks'] != null ? Map<String, dynamic>.from(map['tasks']) : null,
      payments: map['payments'] != null
          ? Map<String, dynamic>.from(map['payments'])
          : null,
      createdAt: _parseTimestamp(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? _parseTimestamp(map['completedAt'])
          : null,
      workerName: map['workerName'],
      budget: (map['budget'] as num?)?.toDouble(),
      platformFee: (map['platformFee'] ?? 0.0).toDouble(),
      netEarnings: (map['netEarnings'] ?? 0.0).toDouble(),
      escrowBalance: (map['escrowBalance'] ?? 0.0).toDouble(),
      // New fields
      projectType: map['projectType'],
      contractId: map['contractId'],
      milestoneIds: map['milestoneIds'] != null
          ? List<String>.from(map['milestoneIds'])
          : null,
      disputeId: map['disputeId'],
      ownerRatingId: map['ownerRatingId'],
      workerRatingId: map['workerRatingId'],
      startDate:
          map['startDate'] != null ? _parseTimestamp(map['startDate']) : null,
      deadline:
          map['deadline'] != null ? _parseTimestamp(map['deadline']) : null,
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble(),
      sharedFiles: map['sharedFiles'] != null
          ? List<Map<String, dynamic>>.from((map['sharedFiles'] as List)
              .map((e) => Map<String, dynamic>.from(e)))
          : null,
      depositPaid: map['depositPaid'] ?? false,
      termsAndConditions: map['termsAndConditions'],
      requiredDeposit: (map['requiredDeposit'] as num?)?.toDouble(),
    );
  }

  static int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'workerId': workerId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'progress': progress,
      'status': status,
      'tasks': tasks,
      'payments': payments,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'workerName': workerName,
      'budget': budget,
      'platformFee': platformFee,
      'netEarnings': netEarnings,
      'escrowBalance': escrowBalance,
      // New fields
      'projectType': projectType,
      'contractId': contractId,
      'milestoneIds': milestoneIds,
      'disputeId': disputeId,
      'ownerRatingId': ownerRatingId,
      'workerRatingId': workerRatingId,
      'startDate': startDate,
      'deadline': deadline,
      'hourlyRate': hourlyRate,
      'sharedFiles': sharedFiles,
      'depositPaid': depositPaid,
      'termsAndConditions': termsAndConditions,
      'requiredDeposit': requiredDeposit,
    };
  }
}

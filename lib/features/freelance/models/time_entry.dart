import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeEntryStatus {
  pending,
  approved,
  rejected,
}

class TimeEntry {
  final String id;
  final String projectId;
  final String workerId;
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final double hours;
  final TimeEntryStatus status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime createdAt;

  TimeEntry({
    required this.id,
    required this.projectId,
    required this.workerId,
    required this.startTime,
    required this.endTime,
    required this.description,
    double? hours,
    this.status = TimeEntryStatus.pending,
    this.rejectionReason,
    this.approvedAt,
    DateTime? createdAt,
  })  : hours = hours ?? _calculateHours(startTime, endTime),
        createdAt = createdAt ?? DateTime.now();

  static double _calculateHours(DateTime start, DateTime end) {
    return end.difference(start).inMinutes / 60.0;
  }

  factory TimeEntry.fromMap(String id, Map<String, dynamic> map) {
    return TimeEntry(
      id: id,
      projectId: map['projectId'] ?? '',
      workerId: map['workerId'] ?? '',
      startTime: _parseTimestamp(map['startTime']),
      endTime: _parseTimestamp(map['endTime']),
      description: map['description'] ?? '',
      hours: (map['hours'] ?? 0.0).toDouble(),
      status: TimeEntryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TimeEntryStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      approvedAt:
          map['approvedAt'] != null ? _parseTimestamp(map['approvedAt']) : null,
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
      'workerId': workerId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'description': description,
      'hours': hours,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TimeEntry copyWith({
    TimeEntryStatus? status,
    String? rejectionReason,
    DateTime? approvedAt,
  }) {
    return TimeEntry(
      id: id,
      projectId: projectId,
      workerId: workerId,
      startTime: startTime,
      endTime: endTime,
      description: description,
      hours: hours,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt,
    );
  }
}




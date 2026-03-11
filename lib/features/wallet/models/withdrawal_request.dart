import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class WithdrawalRequest {
  final String id;
  final String userId;
  final double amount;
  final WithdrawalStatus status;
  final String bankAccountId;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? upiId;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? adminId; // Admin who processed
  final String? failureReason;
  final String? transactionId; // Bank transaction ID

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.amount,
    this.status = WithdrawalStatus.pending,
    required this.bankAccountId,
    this.bankAccountName,
    this.bankAccountNumber,
    this.ifscCode,
    this.upiId,
    DateTime? requestedAt,
    this.processedAt,
    this.completedAt,
    this.adminId,
    this.failureReason,
    this.transactionId,
  }) : requestedAt = requestedAt ?? DateTime.now();

  factory WithdrawalRequest.fromMap(String id, Map<String, dynamic> map) {
    return WithdrawalRequest(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      bankAccountId: map['bankAccountId'] ?? '',
      bankAccountName: map['bankAccountName'],
      bankAccountNumber: map['bankAccountNumber'],
      ifscCode: map['ifscCode'],
      upiId: map['upiId'],
      requestedAt: _parseTimestamp(map['requestedAt']),
      processedAt: map['processedAt'] != null
          ? _parseTimestamp(map['processedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? _parseTimestamp(map['completedAt'])
          : null,
      adminId: map['adminId'],
      failureReason: map['failureReason'],
      transactionId: map['transactionId'],
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
      'userId': userId,
      'amount': amount,
      'status': status.name,
      'bankAccountId': bankAccountId,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'adminId': adminId,
      'failureReason': failureReason,
      'transactionId': transactionId,
    };
  }

  WithdrawalRequest copyWith({
    String? id,
    String? userId,
    WithdrawalStatus? status,
    DateTime? processedAt,
    DateTime? completedAt,
    String? adminId,
    String? failureReason,
    String? transactionId,
  }) {
    return WithdrawalRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount,
      status: status ?? this.status,
      bankAccountId: bankAccountId,
      bankAccountName: bankAccountName,
      bankAccountNumber: bankAccountNumber,
      ifscCode: ifscCode,
      upiId: upiId,
      requestedAt: requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      adminId: adminId ?? this.adminId,
      failureReason: failureReason ?? this.failureReason,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}




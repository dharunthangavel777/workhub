import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:work_hub/features/wallet/models/transaction.dart';
import 'package:work_hub/features/wallet/models/withdrawal_request.dart';
import 'package:work_hub/core/services/payment_orchestrator_service.dart';

class WalletRepository {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;

  Future<void> createTransaction(Transaction transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      debugPrint("Create Transaction Error: $e");
      throw Exception("Failed to create transaction: $e");
    }
  }

  Stream<List<Transaction>> getTransactionHistory(String projectId) {
    return _firestore
        .collection('transactions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Transaction.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<Transaction>> getTransactionHistoryFuture(
      String projectId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Transaction.fromMap(doc.id, doc.data()))
        .toList();
  }

  final PaymentOrchestratorService _paymentOrchestrator =
      PaymentOrchestratorService();

  Future<void> requestWithdrawal(WithdrawalRequest request) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // 1. Add/Get Beneficiary
      // In a real app, you might check if beneficiary exists first or cache the ID.
      // Here we add/update it to ensure we have the latest details.
      final beneficiaryData = await _paymentOrchestrator.addBeneficiary(
        userId: user.uid,
        name: request.bankAccountName ?? 'User',
        email: user.email ?? 'user@example.com',
        // Phone is required by most PGs
        phone: user.phoneNumber ?? '9876543210',
        bankAccount: request.bankAccountNumber ?? request.upiId ?? '',
        ifsc: request.ifscCode ?? '',
        address: '123 Digital Lane', // Placeholder if not collected
        city: 'Internet City',
        state: 'Digital State',
        pincode: '000000',
      );

      final beneficiaryId = beneficiaryData['beneficiaryId'];

      // 2. Initiate Withdrawal via Orchestrator
      await _paymentOrchestrator.initiateWithdrawal(
        userId: user.uid,
        amount: request.amount,
        beneficiaryId: beneficiaryId,
      );
    } catch (e) {
      debugPrint("Request Withdrawal Error: $e");
      throw Exception("Failed to submit withdrawal request: $e");
    }
  }

  Future<void> updateWithdrawalStatus(
    String withdrawalId,
    WithdrawalStatus status, {
    String? failureReason,
    String? transactionId,
  }) async {
    try {
      final updates = {
        'status': status.name,
        'updatedAt': firestore.FieldValue.serverTimestamp(),
        if (failureReason != null) 'failureReason': failureReason,
        if (transactionId != null) 'transactionId': transactionId,
      };

      await _firestore
          .collection('withdrawals')
          .doc(withdrawalId)
          .update(updates);
    } catch (e) {
      throw Exception("Failed to update withdrawal status: $e");
    }
  }

  Stream<List<WithdrawalRequest>> getWithdrawalsStream(String userId) {
    return _firestore
        .collection('withdrawals')
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromMap(
              doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<WithdrawalRequest>> getPendingWithdrawalsStream() {
    return _firestore
        .collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromMap(
              doc.id, doc.data()))
          .toList();
    });
  }
}




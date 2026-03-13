import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:work_hub/features/job/domain/models/job.dart';
import 'package:work_hub/features/freelance/models/project.dart';
import 'package:work_hub/features/common/contract/models/contract.dart';
import 'package:work_hub/features/freelance/models/milestone.dart';
import 'package:work_hub/features/wallet/models/transaction.dart'
    as transaction_model;
import 'package:work_hub/features/common/dispute/models/dispute.dart';
import 'package:work_hub/features/wallet/models/withdrawal_request.dart';
import 'package:work_hub/features/profile/domain/models/rating.dart';
import 'package:work_hub/features/freelance/models/time_entry.dart';
import 'package:work_hub/core/services/storage_service.dart';
import 'package:work_hub/core/services/notification_service.dart';
import 'package:work_hub/core/constants/api_constants.dart';

class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  Stream<List<Job>> getJobPostsStream() {
    return _firestore.collection('job_posts').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data(), postType: 'job'))
          .where((post) {
        final isVisible = post.status == 'approved' || post.status == 'pending';
        final isNotExpired =
            post.deadline == null || post.deadline!.isAfter(DateTime.now());
        final isNotFull = post.maxApplications == null ||
            post.applicationsCount < post.maxApplications!;
        return isVisible && isNotExpired && isNotFull;
      }).toList();
      // Sort in memory to avoid index requirements
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Job>> getProjectPostsStream() {
    return _firestore.collection('project_posts').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data(), postType: 'project'))
          .where((post) {
        final isVisible = post.status == 'approved' || post.status == 'pending';
        final isNotExpired =
            post.deadline == null || post.deadline!.isAfter(DateTime.now());
        final isNotFull = post.maxApplications == null ||
            post.applicationsCount < post.maxApplications!;
        return isVisible && isNotExpired && isNotFull;
      }).toList();
      // Sort in memory
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> applyForJob(
    String jobId,
    String userId,
    Map<String, dynamic> applicationData,
    String mode,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");
    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse('${ApiConstants.apiBaseUrl}/applyForJob'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'jobId': jobId,
        'applicationData': {
          ...applicationData,
          'ownerId': applicationData['ownerId'] ?? '',
        },
        'mode': mode,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? "Application failed");
    }
  }

  Future<void> updateApplicationStatus(
    String jobId,
    String userId,
    String status,
    String mode, {
    String? rejectionDescription,
    String? shortlistGreeting,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/updateApplicationStatus'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'jobId': jobId,
          'targetUserId': userId,
          'status': status,
          'mode': mode,
          if (rejectionDescription != null)
            'rejectionDescription': rejectionDescription,
          if (shortlistGreeting != null) 'shortlistGreeting': shortlistGreeting,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Status update failed");
      }

      debugPrint("Application status updated to $status for user $userId");
    } catch (e) {
      debugPrint("Update Application Status Error: $e");
      throw Exception("Failed to update status: $e");
    }
  }

  Stream<List<dynamic>> getWorkerApplicationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('applications')
        .snapshots()
        .asyncMap((snapshot) async {
      debugPrint(
          "Fetching worker applications. Found ${snapshot.docs.length} docs in subcollection.");

      final futures = snapshot.docs.map((doc) async {
        try {
          final jobId = doc.id;
          final docData = doc.data();
          final mode = docData['mode'] ?? 'job';
          final appliedAtData = docData['appliedAt'] ?? docData['timestamp'];

          DateTime? appliedAt;
          if (appliedAtData != null) {
            if (appliedAtData is Timestamp) {
              appliedAt = appliedAtData.toDate();
            } else if (appliedAtData is int) {
              appliedAt = DateTime.fromMillisecondsSinceEpoch(appliedAtData);
            }
          }

          String collection =
              (mode == 'freelancer') ? 'project_posts' : 'job_posts';

          DocumentSnapshot jobDoc = await _firestore
              .collection(collection)
              .doc(jobId)
              .get()
              .timeout(const Duration(seconds: 3));

          // Fallback if not found in preferred collection
          if (!jobDoc.exists) {
            final otherCollection =
                (collection == 'job_posts') ? 'project_posts' : 'job_posts';
            jobDoc = await _firestore
                .collection(otherCollection)
                .doc(jobId)
                .get()
                .timeout(const Duration(seconds: 3));
            if (jobDoc.exists) collection = otherCollection;
          }

          if (jobDoc.exists) {
            final type = (collection == 'project_posts') ? 'project' : 'job';
            return Job.fromMap(jobId, jobDoc.data() as Map<String, dynamic>,
                postType: type, appliedAt: appliedAt);
          } else {
            debugPrint("Job/Project document not found for ID: $jobId");
            return null;
          }
        } catch (e) {
          debugPrint("Error fetching detail for application ${doc.id}: $e");
          return null;
        }
      });

      final results = await Future.wait(futures);
      final List<dynamic> appliedPosts =
          results.where((p) => p != null).map((p) => p!).toList();

      // Sort by appliedAt descending (newest first)
      appliedPosts.sort((a, b) {
        final timeA = a.appliedAt ?? a.createdAt;
        final timeB = b.appliedAt ?? b.createdAt;
        return timeB.compareTo(timeA);
      });
      return appliedPosts;
    });
  }

  Future<List<dynamic>> getWorkerApplications(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('applications')
        .get()
        .timeout(const Duration(seconds: 5));

    final futures = snapshot.docs.map((doc) async {
      try {
        final jobId = doc.id;
        final docData = doc.data();
        final mode = docData['mode'] ?? 'job';
        final appliedAtData = docData['appliedAt'] ?? docData['timestamp'];

        DateTime? appliedAt;
        if (appliedAtData != null) {
          if (appliedAtData is Timestamp) {
            appliedAt = appliedAtData.toDate();
          } else if (appliedAtData is int) {
            appliedAt = DateTime.fromMillisecondsSinceEpoch(appliedAtData);
          }
        }

        String collection =
            (mode == 'freelancer') ? 'project_posts' : 'job_posts';

        DocumentSnapshot jobDoc = await _firestore
            .collection(collection)
            .doc(jobId)
            .get()
            .timeout(const Duration(seconds: 3));

        if (!jobDoc.exists) {
          final otherCollection =
              (collection == 'job_posts') ? 'project_posts' : 'job_posts';
          jobDoc = await _firestore
              .collection(otherCollection)
              .doc(jobId)
              .get()
              .timeout(const Duration(seconds: 3));
          if (jobDoc.exists) collection = otherCollection;
        }

        if (jobDoc.exists) {
          final type = (collection == 'project_posts') ? 'project' : 'job';
          return Job.fromMap(jobId, jobDoc.data() as Map<String, dynamic>,
              postType: type, appliedAt: appliedAt);
        } else {
          debugPrint("Job/Project document not found for ID: $jobId");
          return null;
        }
      } catch (e) {
        debugPrint("Error fetching detail for application ${doc.id}: $e");
        return null;
      }
    });

    final results = await Future.wait(futures);
    final List<dynamic> appliedPosts =
        results.where((p) => p != null).map((p) => p!).toList();

    // Sort by appliedAt descending (newest first)
    appliedPosts.sort((a, b) {
      final timeA = a.appliedAt ?? a.createdAt;
      final timeB = b.appliedAt ?? b.createdAt;
      return timeB.compareTo(timeA);
    });
    return appliedPosts;
  }

  Future<void> submitBid(
    String projectId,
    String userId,
    Map<String, dynamic> bidData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");
    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse('${ApiConstants.apiBaseUrl}/submitBid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'projectId': projectId,
        'bidData': {
          ...bidData,
          'ownerId': bidData['ownerId'] ?? '',
        },
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? "Bid submission failed");
    }
  }

  Stream<List<Project>> getWorkerProjectsStream(String userId) {
    return _firestore
        .collection('projects')
        .where('workerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .update(updates)
        .timeout(const Duration(seconds: 5));
  }

  Future<void> releasePayment(String projectId, double amount,
      {String? milestoneId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/releasePayment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'amount': amount,
          'milestoneId': milestoneId,
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode != 200 || result['success'] != true) {
        throw Exception(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      debugPrint("Release Payment Error: $e");
      throw Exception("Failed to release payment: $e");
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update(updates)
        .timeout(const Duration(seconds: 5));
  }

  // ========== CONTRACT MANAGEMENT ==========

  /// Create a contract for a project
  Future<String> createContract({
    required String projectId,
    required double agreedBudget,
    required String paymentType,
    DateTime? startDate,
    DateTime? expectedCompletion,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/createContract'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'agreedBudget': agreedBudget,
          'paymentType': paymentType,
          'startDate': startDate?.toIso8601String(),
          'expectedCompletion': expectedCompletion?.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Contract creation failed");
      }

      final result = jsonDecode(response.body);
      return result['contractId'];
    } catch (e) {
      debugPrint("Create Contract Error: $e");
      throw Exception("Failed to create contract: $e");
    }
  }

  /// Accept a contract (by owner or worker)
  Future<void> acceptContract(
    String contractId,
    String userId,
    String role,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/acceptContract'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'contractId': contractId,
          'role': role,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Contract acceptance failed");
      }

      debugPrint("Contract accepted by $role: $contractId");
    } catch (e) {
      debugPrint("Accept Contract Error: $e");
      throw Exception("Failed to accept contract: $e");
    }
  }

  /// Get contract by contract ID
  Future<Contract?> getContract(String contractId) async {
    try {
      final doc = await _firestore
          .collection('contracts')
          .doc(contractId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        return Contract.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("Get Contract Error: $e");
      return null;
    }
  }

  /// Get contract by project ID
  Future<Contract?> getContractByProjectId(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('projectId', isEqualTo: projectId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Contract.fromMap(doc.id, doc.data());
      }
      return null;
    } catch (e) {
      debugPrint("Get Contract by Project ID Error: $e");
      return null;
    }
  }

  // ========== ESCROW MANAGEMENT ==========

  /// Deposit funds to escrow after successful payment
  Future<void> depositToEscrow({
    required String projectId,
    required double amount,
    required String paymentSessionId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final projectRef = _firestore.collection('projects').doc(projectId);
        final projectDoc = await transaction.get(projectRef);

        if (!projectDoc.exists) {
          throw Exception("Project not found");
        }

        // Update deposit flag (Redundant but safe for local UI state)
        transaction.update(projectRef, {
          'depositPaid': true,
        });

        // NOTE: escrowBalance and pendingClearance are now updated by the backend
        // during verifyPaymentStatus to ensure a single source of truth and prevent doubling.
        // Transaction record is also created by the backend.
      }).timeout(const Duration(seconds: 10));

      debugPrint("Escrow deposit successful: \$$amount for project $projectId");
    } catch (e) {
      debugPrint("Deposit to Escrow Error: $e");
      throw Exception("Failed to deposit to escrow: $e");
    }
  }

  /// Get escrow balance for a project
  Future<double> getEscrowBalance(String projectId) async {
    try {
      final doc = await _firestore
          .collection('projects')
          .doc(projectId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        return (doc.data()!['escrowBalance'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint("Get Escrow Balance Error: $e");
      return 0.0;
    }
  }

  // ========== TRANSACTION TRACKING ==========

  /// Create a transaction record
  Future<String> createTransaction(
      transaction_model.Transaction transaction) async {
    try {
      final transactionRef = _firestore.collection('transactions').doc();
      final transactionWithId = transaction_model.Transaction(
        id: transactionRef.id,
        projectId: transaction.projectId,
        userId: transaction.userId,
        type: transaction.type,
        amount: transaction.amount,
        description: transaction.description,
        relatedMilestoneId: transaction.relatedMilestoneId,
        metadata: transaction.metadata,
      );

      await transactionRef
          .set(transactionWithId.toMap())
          .timeout(const Duration(seconds: 5));

      debugPrint("Transaction created: ${transactionRef.id}");
      return transactionRef.id;
    } catch (e) {
      debugPrint("Create Transaction Error: $e");
      throw Exception("Failed to create transaction: $e");
    }
  }

  /// Get transaction history for a project
  Future<List<transaction_model.Transaction>> getTransactionHistory(
      String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 5));

      return snapshot.docs
          .map((doc) =>
              transaction_model.Transaction.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint("Get Transaction History Error: $e");
      return [];
    }
  }

  // ------------------------------------------------------------------------
  // MILESTONE METHODS
  // ------------------------------------------------------------------------

  Future<void> createMilestone(String projectId, Milestone milestone) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestone.id)
          .set(milestone.toMap());
    } catch (e) {
      throw Exception('Failed to create milestone: $e');
    }
  }

  Stream<List<Milestone>> getMilestonesStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('milestones')
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Milestone.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> submitMilestoneWork(
    String projectId,
    String milestoneId,
    String note,
    List<String> links,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/submitMilestone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'milestoneId': milestoneId,
          'note': note,
          'links': links,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Milestone submission failed");
      }

      debugPrint("Milestone $milestoneId submitted for project $projectId");
    } catch (e) {
      debugPrint("Submit Milestone Error: $e");
      throw Exception("Failed to submit milestone work: $e");
    }
  }

  Future<void> approveMilestone(String projectId, String milestoneId) async {
    try {
      final milestoneDataDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId)
          .get();

      if (!milestoneDataDoc.exists) throw Exception("Milestone not found");
      final double mileAmount =
          (milestoneDataDoc.data()?['amount'] ?? 0.0).toDouble();

      // All validation, status updates, and fund movements happen on the server
      await releasePayment(projectId, mileAmount, milestoneId: milestoneId);

      // Sync project progress (Post-backend update)
      await syncProjectProgress(projectId);
    } catch (e) {
      debugPrint("Approve Milestone Error: $e");
      throw Exception('Failed to approve milestone: $e');
    }
  }

  Future<void> syncProjectProgress(String projectId) async {
    // REDUNDANT: Handled server-side by releasePayment endpoint
    debugPrint(
        "Progress sync requested for project $projectId (Handled server-side)");
  }

  Future<void> updateMilestoneAgreedStatus(
    String projectId,
    String milestoneId,
    bool agreed,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/agreeToMilestone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'milestoneId': milestoneId,
          'agreed': agreed,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Agreement update failed");
      }

      debugPrint("Agreement updated for milestone $milestoneId");
    } catch (e) {
      debugPrint("Update Agreement Error: $e");
      throw Exception('Failed to update milestone agreement: $e');
    }
  }

  Future<void> rejectMilestone(
      String projectId, String milestoneId, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/rejectMilestone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'milestoneId': milestoneId,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Milestone rejection failed");
      }

      debugPrint("Milestone $milestoneId rejected for project $projectId");
    } catch (e) {
      debugPrint("Reject Milestone Error: $e");
      throw Exception("Failed to reject milestone: $e");
    }
  }

  // -------------------------
  // Withdrawal Management
  // -------------------------

  Future<void> requestWithdrawal(WithdrawalRequest request) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/requestWithdrawal'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': request.amount,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Withdrawal failed");
      }

      debugPrint("Withdrawal request submitted for ₹${request.amount}");
    } catch (e) {
      debugPrint("Request Withdrawal Error: $e");
      throw Exception("Failed to request withdrawal: $e");
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
        'processedAt': FieldValue.serverTimestamp(),
        if (status == WithdrawalStatus.completed)
          'completedAt': FieldValue.serverTimestamp(),
        if (failureReason != null) 'failureReason': failureReason,
        if (transactionId != null) 'transactionId': transactionId,
      };

      await _firestore
          .collection('withdrawals')
          .doc(withdrawalId)
          .update(updates);

      // Trigger Notification
      final withdrawalDoc =
          await _firestore.collection('withdrawals').doc(withdrawalId).get();
      final recipientId = withdrawalDoc.data()?['userId'];
      if (recipientId != null) {
        NotificationService().sendNotification(
          recipientId: recipientId,
          title: 'Withdrawal Update',
          body:
              'Your withdrawal request status has been updated to ${status.name}.',
          category: 'withdrawal_status',
          data: {'withdrawalId': withdrawalId},
        );
      }
      debugPrint("Withdrawal $withdrawalId updated to $status");
    } catch (e) {
      debugPrint("Update Withdrawal Status Error: $e");
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
      return snapshot.docs.map((doc) {
        return WithdrawalRequest.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // -------------------------
  // Dispute Management
  // -------------------------

  Future<void> raiseDispute(DisputeInfo dispute) async {
    await _firestore
        .collection('disputes')
        .doc(dispute.id)
        .set(dispute.toMap());

    // Trigger Notification
    final projectDoc =
        await _firestore.collection('projects').doc(dispute.projectId).get();
    final workerId = projectDoc.data()?['workerId'];
    final ownerId = projectDoc.data()?['ownerId'];
    final recipientId = (dispute.raisedBy == ownerId) ? workerId : ownerId;

    if (recipientId != null) {
      NotificationService().sendNotification(
        recipientId: recipientId,
        title: 'Dispute Raised',
        body: 'A dispute has been opened for your project: ${dispute.reason}',
        category: 'dispute_raised',
        data: {'projectId': dispute.projectId, 'disputeId': dispute.id},
      );
    }
  }

  Stream<List<DisputeInfo>> getDisputesStream(String projectId) {
    return _firestore
        .collection('disputes')
        .where('projectId', isEqualTo: projectId)
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DisputeInfo.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // -------------------------
  // Admin Methods
  // -------------------------

  Stream<List<WithdrawalRequest>> getPendingWithdrawalsStream() {
    return _firestore
        .collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WithdrawalRequest.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<DisputeInfo>> getAllDisputesStream() {
    return _firestore
        .collection('disputes')
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DisputeInfo.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // ========== FILE SHARING ==========

  Future<void> uploadProjectFile({
    required String projectId,
    required File file,
    required String fileName,
    required String userId,
    required String userName,
  }) async {
    try {
      final path =
          'projects/$projectId/shared_files/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final downloadUrl = await _storage.uploadFile(path, file);

      if (downloadUrl == null) throw Exception("Failed to upload file");

      final fileMetadata = {
        'name': fileName,
        'url': downloadUrl,
        'size': await file.length(),
        'uploadedBy': userId,
        'uploadedByName': userName,
        'uploadedAt': DateTime.now().millisecondsSinceEpoch,
        'storagePath': path,
      };

      await _firestore.collection('projects').doc(projectId).update({
        'sharedFiles': FieldValue.arrayUnion([fileMetadata]),
      });

      debugPrint("File uploaded successfully to project $projectId: $fileName");
    } catch (e) {
      debugPrint("Upload Project File Error: $e");
      throw Exception("Failed to upload file: $e");
    }
  }

  Future<void> deleteProjectFile({
    required String projectId,
    required Map<String, dynamic> fileMetadata,
  }) async {
    try {
      // 1. Delete from Supabase Storage
      final storagePath = fileMetadata['storagePath'];
      if (storagePath != null) {
        await _storage.deleteFile(storagePath);
      }

      // 2. Remove from Firestore
      await _firestore.collection('projects').doc(projectId).update({
        'sharedFiles': FieldValue.arrayRemove([fileMetadata]),
      });

      debugPrint("File deleted successfully from project $projectId");
    } catch (e) {
      debugPrint("Delete Project File Error: $e");
      throw Exception("Failed to delete file: $e");
    }
  }

  // ========== RATINGS & REVIEWS ==========

  Future<void> submitRating(Rating rating) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/submitRating'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'targetUserId': rating.ratedUser,
          'projectId': rating.projectId,
          'rating': rating.score,
          'review': rating.review,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Rating submission failed");
      }

      debugPrint("Rating submitted successfully for ${rating.ratedUser}");
    } catch (e) {
      debugPrint("Submit Rating Error: $e");
      throw Exception("Failed to submit rating: $e");
    }
  }

  Future<Rating?> getRatingById(String ratingId) async {
    try {
      final doc = await _firestore.collection('ratings').doc(ratingId).get();
      if (doc.exists && doc.data() != null) {
        return Rating.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("Get Rating Error: $e");
      return null;
    }
  }

  Future<Rating?> getRatingByProjectAndRole(
      String projectId, String raterRole) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('projectId', isEqualTo: projectId)
          .where('raterRole', isEqualTo: raterRole)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Rating.fromMap(doc.id, doc.data());
      }
      return null;
    } catch (e) {
      debugPrint("Get Rating Error: $e");
      return null;
    }
  }

  Stream<List<Rating>> getReviewsStream(String userId) {
    return _firestore
        .collection('ratings')
        .where('ratedUser', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Rating.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // ========== TIME TRACKING ==========

  Future<void> logTimeEntry(String projectId, TimeEntry entry) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('time_entries')
          .doc(entry.id.isEmpty ? null : entry.id)
          .set(entry.toMap());
      debugPrint("Time entry logged for project $projectId");
    } catch (e) {
      debugPrint("Log Time Entry Error: $e");
      throw Exception("Failed to log time entry: $e");
    }
  }

  Stream<List<TimeEntry>> getTimeEntriesStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('time_entries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateTimeEntryStatus(
    String projectId,
    String entryId,
    TimeEntryStatus status, {
    String? rejectionReason,
  }) async {
    try {
      final updates = {
        'status': status.name,
        if (status == TimeEntryStatus.approved) 'approvedAt': Timestamp.now(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('time_entries')
          .doc(entryId)
          .update(updates);

      debugPrint("Time entry $entryId status updated to ${status.name}");
    } catch (e) {
      debugPrint("Update Time Entry Status Error: $e");
      throw Exception("Failed to update time entry status: $e");
    }
  }

  // ========== SAVED JOBS & PROJECTS ==========

  Future<void> toggleSaveOpportunity({
    required String userId,
    required String opportunityId,
    required String type, // 'job' or 'project'
    required bool isSaving,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final field = type == 'job' ? 'savedJobIds' : 'savedProjectIds';

      await userRef.update({
        field: isSaving
            ? FieldValue.arrayUnion([opportunityId])
            : FieldValue.arrayRemove([opportunityId]),
      });

      debugPrint(
          "Opportunity $opportunityId ${isSaving ? 'saved' : 'unsaved'} for user $userId");
    } catch (e) {
      debugPrint("Toggle Save Opportunity Error: $e");
      throw Exception("Failed to update saved items: $e");
    }
  }

  Future<String> uploadDisputeFile({
    required String projectId,
    required File file,
    required String fileName,
  }) async {
    try {
      final path =
          'disputes/$projectId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final downloadUrl = await _storage.uploadFile(path, file);

      if (downloadUrl == null) throw Exception("Failed to upload evidence");

      return downloadUrl;
    } catch (e) {
      debugPrint("Upload Dispute File Error: $e");
      throw Exception("Failed to upload evidence: $e");
    }
  }

  Future<void> processDeposit(String projectId, double amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/processDeposit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'amount': amount,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Deposit failed");
      }

      debugPrint("Deposit processed successfully for project $projectId");
    } catch (e) {
      debugPrint("Process Deposit Error: $e");
      throw Exception("Failed to process deposit: $e");
    }
  }
}

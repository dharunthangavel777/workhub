import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_post_model.dart';
import '../models/project_post_model.dart';
import '../models/project_model.dart';
import '../models/contract_terms_model.dart';
import '../models/milestone_model.dart';
import '../models/transaction_model.dart' as transaction_model;
import '../models/dispute_model.dart';
import '../models/withdrawal_request_model.dart';
import '../models/rating_model.dart';
import '../models/time_entry_model.dart';
import '../services/storage_service.dart';
import '../../logic/services/notification_service.dart';

class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  Stream<List<JobPostModel>> getJobPostsStream() {
    return _firestore.collection('job_posts').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => JobPostModel.fromMap(doc.id, doc.data()))
          .where((post) => post.status == 'approved')
          .toList();
      // Sort in memory to avoid index requirements
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<ProjectPostModel>> getProjectPostsStream() {
    return _firestore.collection('project_posts').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ProjectPostModel.fromMap(doc.id, doc.data()))
          .where((post) => post.status == 'approved')
          .toList();
      // Sort in memory
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> postJob(JobPostModel job) async {
    await _firestore
        .collection('job_posts')
        .add(job.toMap())
        .timeout(const Duration(seconds: 5));
  }

  Future<void> postProject(ProjectPostModel project) async {
    await _firestore
        .collection('project_posts')
        .add(project.toMap())
        .timeout(const Duration(seconds: 5));
  }

  Future<void> applyForJob(
    String jobId,
    String userId,
    Map<String, dynamic> applicationData,
    String mode,
  ) async {
    final collection = mode == 'freelancer' ? 'project_posts' : 'job_posts';
    final docRef = _firestore.collection(collection).doc(jobId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) throw Exception("Job not found");

      final data = doc.data()!;
      final status = data['status'] ?? 'pending';
      final openings = data['openings'] ?? 1;
      final maxApps = data['maxApplications'] ?? openings;
      final currentApps = data['applicationsCount'] ?? 0;

      if (status != 'approved') {
        throw Exception("This job is no longer accepting applications.");
      }

      if (currentApps >= maxApps) {
        throw Exception("Application limit reached for this job.");
      }

      transaction.update(docRef, {
        'applicants.$userId': {...applicationData, 'mode': mode},
        'applicationsCount': FieldValue.increment(1),
        if (currentApps + 1 >= maxApps) 'status': 'filled',
      });

      transaction.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('applications')
            .doc(jobId),
        {
          'status': 'pending',
          'appliedAt': DateTime.now().millisecondsSinceEpoch,
          'mode': mode,
        },
      );
    }).timeout(const Duration(seconds: 10));

    // Trigger Notification
    if (mode == 'worker') {
      NotificationService().sendNotification(
        recipientId: (applicationData['ownerId'] ?? ''),
        title: 'New Application',
        body: 'Someone has applied for your job post.',
        category: 'job_application',
        data: {'jobId': jobId},
      );
    }
  }

  Future<void> updateApplicationStatus(
    String jobId,
    String userId,
    String status,
    String mode,
  ) async {
    final collection = mode == 'freelancer' ? 'project_posts' : 'job_posts';
    final batch = _firestore.batch();

    batch.update(_firestore.collection(collection).doc(jobId), {
      'applicants.$userId.status': status,
    });

    batch.update(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('applications')
          .doc(jobId),
      {'status': status},
    );

    await batch.commit().timeout(const Duration(seconds: 5));

    // Trigger Notification
    NotificationService().sendNotification(
      recipientId: userId,
      title: 'Application Update',
      body: 'Your application status has been updated to $status.',
      category: 'application_status',
      data: {'jobId': jobId},
    );
  }

  Stream<List<dynamic>> getWorkerApplicationsStream(String userId,
      {String? modeFilter}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('applications')
        .snapshots()
        .asyncMap((snapshot) async {
      final List<dynamic> appliedPosts = [];

      for (var doc in snapshot.docs) {
        final jobId = doc.id;
        final mode = doc.data()['mode'] ?? 'job';

        // Filter by mode if provided
        if (modeFilter != null && mode != modeFilter) {
          continue;
        }

        final collection = mode == 'freelancer' ? 'project_posts' : 'job_posts';

        final jobDoc = await _firestore
            .collection(collection)
            .doc(jobId)
            .get()
            .timeout(const Duration(seconds: 5));
        if (jobDoc.exists) {
          if (mode == 'freelancer') {
            appliedPosts.add(ProjectPostModel.fromMap(jobId, jobDoc.data()!));
          } else {
            appliedPosts.add(JobPostModel.fromMap(jobId, jobDoc.data()!));
          }
        }
      }
      // Sort by some criteria if needed, e.g. status or title
      return appliedPosts;
    });
  }

  Future<List<dynamic>> getWorkerApplications(String userId,
      {String? modeFilter}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('applications')
        .get()
        .timeout(const Duration(seconds: 5));

    final List<dynamic> appliedPosts = [];

    for (var doc in snapshot.docs) {
      final jobId = doc.id;
      final mode = doc.data()['mode'] ?? 'job';

      // Filter by mode if provided
      if (modeFilter != null && mode != modeFilter) {
        continue;
      }

      final collection = mode == 'freelancer' ? 'project_posts' : 'job_posts';

      final jobDoc = await _firestore
          .collection(collection)
          .doc(jobId)
          .get()
          .timeout(const Duration(seconds: 5));
      if (jobDoc.exists) {
        if (mode == 'freelancer') {
          appliedPosts.add(ProjectPostModel.fromMap(jobId, jobDoc.data()!));
        } else {
          appliedPosts.add(JobPostModel.fromMap(jobId, jobDoc.data()!));
        }
      }
    }
    return appliedPosts;
  }

  Future<List<JobPostModel>> getOwnerJobPosts(String ownerId) async {
    final snapshot = await _firestore
        .collection('job_posts')
        .where('ownerId', isEqualTo: ownerId)
        .get()
        .timeout(const Duration(seconds: 5));

    return snapshot.docs.map((doc) {
      return JobPostModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<List<ProjectPostModel>> getOwnerProjectPosts(String ownerId) async {
    final snapshot = await _firestore
        .collection('project_posts')
        .where('ownerId', isEqualTo: ownerId)
        .get()
        .timeout(const Duration(seconds: 5));

    return snapshot.docs.map((doc) {
      return ProjectPostModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  Stream<List<JobPostModel>> getOwnerJobPostsStream(String ownerId) {
    return _firestore
        .collection('job_posts')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return JobPostModel.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<ProjectPostModel>> getOwnerProjectPostsStream(String ownerId) {
    return _firestore
        .collection('project_posts')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return ProjectPostModel.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> submitBid(
    String projectId,
    String userId,
    Map<String, dynamic> bidData,
  ) async {
    final docRef = _firestore.collection('project_posts').doc(projectId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) throw Exception("Project not found");

      final data = doc.data()!;
      final status = data['status'] ?? 'pending';
      final maxApps =
          data['maxApplications'] ?? 1000; // Default high if not set
      final currentApps = data['applicationsCount'] ?? 0;

      if (status != 'approved' && status != 'open') {
        throw Exception("This project is no longer accepting proposals.");
      }

      if (currentApps >= maxApps) {
        throw Exception("Application limit reached for this project.");
      }

      // Update the project post with the bid and increment count
      transaction.update(docRef, {
        'applicants.$userId': {
          ...bidData,
          'mode': 'freelancer',
          'status': 'pending',
        },
        'applicationsCount': FieldValue.increment(1),
        if (currentApps + 1 >= maxApps) 'status': 'filled',
      });

      // Record the bid in the user's applications subcollection
      transaction.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('applications')
            .doc(projectId),
        {
          'status': 'pending',
          'appliedAt': DateTime.now().millisecondsSinceEpoch,
          'mode': 'freelancer',
          'bidAmount': bidData['bidAmount'],
          'suggestedMilestones': bidData['suggestedMilestones'],
        },
      );
    }).timeout(const Duration(seconds: 10));

    // Trigger Notification
    NotificationService().sendNotification(
      recipientId: (bidData['ownerId'] ?? ''),
      title: 'New Proposal',
      body: 'A new proposal has been submitted for your project.',
      category: 'project_bid',
      data: {'projectId': projectId},
    );
  }

  Future<void> approveBid(
    String postId,
    String workerId,
    Map<String, dynamic> projectData,
  ) async {
    try {
      final batch = _firestore.batch();

      // Update the bid status to 'approved' in the project post
      batch.update(_firestore.collection('project_posts').doc(postId), {
        'applicants.$workerId.status': 'approved',
        'acceptingBids': false,
        'status': 'setup', // Changed from 'in_progress'
      });

      // Update the worker's application status
      batch.update(
        _firestore
            .collection('users')
            .doc(workerId)
            .collection('applications')
            .doc(postId),
        {'status': 'approved'},
      );

      // Create a new project document
      final projectRef = _firestore.collection('projects').doc();

      final String deliveryTime = projectData['deliveryTime'] ?? '30 days';
      final int durationDays = _parseDurationInDays(deliveryTime);
      final DateTime expectedCompletion =
          DateTime.now().add(Duration(days: durationDays));

      // Create contract for the project
      final contractRef = _firestore.collection('contracts').doc();
      final contractTerms = ContractTerms(
        id: contractRef.id,
        projectId: projectRef.id,
        agreedBudget: (projectData['budget'] ?? 0.0).toDouble(),
        startDate: DateTime.now(),
        expectedCompletion: expectedCompletion,
        paymentType: projectData['mode'] == 'hourly' ? 'hourly' : 'fixed',
        platformFee: 10.0,
        ownerAccepted: false,
        workerAccepted: false,
        additionalTerms: projectData['termsAndConditions'],
      );

      batch.set(contractRef, contractTerms.toMap());

      // Handle Suggested Milestones
      final List<String> milestoneIds = [];
      if (projectData['suggestedMilestones'] != null) {
        final List<dynamic> suggested = projectData['suggestedMilestones'];
        for (var mData in suggested) {
          final mRef = projectRef.collection('milestones').doc();
          final milestone = Milestone(
            id: mRef.id,
            projectId: projectRef.id,
            title: mData['title'] ?? 'Milestone',
            description: mData['description'] ?? '',
            amount: (mData['amount'] ?? 0.0).toDouble(),
            deadline: mData['deadline'] != null
                ? DateTime.fromMillisecondsSinceEpoch(mData['deadline'])
                : DateTime.now().add(const Duration(days: 7)),
            status: MilestoneStatus.pending,
          );
          batch.set(mRef, milestone.toMap());
          milestoneIds.add(mRef.id);
        }
      }

      final double budget = (projectData['budget'] ?? 0.0).toDouble();
      const double platformFeePercent = 10.0;
      final double feeAmount = budget * platformFeePercent / 100;
      final double totalRequired = budget + feeAmount;

      batch.set(projectRef, {
        'id': projectRef.id,
        'jobId': postId,
        'workerId': workerId,
        'ownerId': projectData['ownerId'],
        'title': projectData['title'],
        'description': projectData['description'],
        'workerName': projectData['workerName'],
        'budget': budget,
        'platformFee': platformFeePercent, // Store percent here
        'status': 'setup',
        'createdAt': FieldValue.serverTimestamp(),
        'milestoneIds': milestoneIds,
        'escrowBalance': 0,
        'contractId': contractRef.id,
        'termsAndConditions': projectData['termsAndConditions'],
        'requiredDeposit': totalRequired, // Budget + Fee
        'depositPaid': false,
        'deadline': expectedCompletion.millisecondsSinceEpoch,
      });

      await batch.commit().timeout(const Duration(seconds: 10));

      // Trigger Notification
      NotificationService().sendNotification(
        recipientId: workerId,
        title: 'Proposal Approved',
        body: 'Your proposal has been accepted! You can now start the setup.',
        category: 'bid_approved',
        data: {'projectId': postId},
      );

      debugPrint(
          "Bid approved, project, contract and milestones created successfully");
    } catch (e) {
      debugPrint("Approve Bid Error: $e");
      throw Exception("Failed to approve bid: $e");
    }
  }

  Stream<List<ProjectModel>> getWorkerProjectsStream(String userId) {
    return _firestore
        .collection('projects')
        .where('workerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<ProjectModel>> getOwnerProjectsStream(String ownerId) {
    return _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.id, doc.data()))
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

  Future<void> releasePayment(String projectId, double amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final token = await user.getIdToken();

      // Production Vercel URL
      const String baseUrl = 'https://work-hub-lake.vercel.app';

      final response = await http.post(
        Uri.parse('$baseUrl/releasePayment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'amount': amount,
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode != 200 || result['success'] != true) {
        throw Exception(result['message'] ?? 'Unknown error');
      }

      // Trigger Notification
      final projectDoc =
          await _firestore.collection('projects').doc(projectId).get();
      final workerId = projectDoc.data()?['workerId'];
      if (workerId != null) {
        NotificationService().sendNotification(
          recipientId: workerId,
          title: 'Payment Released',
          body:
              'A payment of $amount has been released from escrow to your wallet.',
          category: 'payment_released',
          data: {'projectId': projectId},
        );
      }
    } catch (e) {
      // Re-throw to be handled by the provider/UI
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
    double platformFee = 10.0,
  }) async {
    try {
      final contractRef = _firestore.collection('contracts').doc();
      final contractTerms = ContractTerms(
        id: contractRef.id,
        projectId: projectId,
        agreedBudget: agreedBudget,
        startDate: startDate ?? DateTime.now(),
        expectedCompletion:
            expectedCompletion ?? DateTime.now().add(const Duration(days: 30)),
        paymentType: paymentType,
        platformFee: platformFee,
      );

      await contractRef.set(contractTerms.toMap()).timeout(
            const Duration(seconds: 5),
          );

      debugPrint("Contract created successfully: ${contractRef.id}");
      return contractRef.id;
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
      final Map<String, dynamic> updates = {};

      if (role == 'owner') {
        updates['ownerAccepted'] = true;
        updates['ownerAcceptedAt'] = Timestamp.now();
      } else if (role == 'worker') {
        updates['workerAccepted'] = true;
        updates['workerAcceptedAt'] = Timestamp.now();
      } else {
        throw Exception("Invalid role: $role");
      }

      await _firestore
          .collection('contracts')
          .doc(contractId)
          .update(updates)
          .timeout(const Duration(seconds: 5));

      // Trigger Notification
      final contractDoc =
          await _firestore.collection('contracts').doc(contractId).get();
      final Map<String, dynamic>? contractData = contractDoc.data();
      final projectId = contractData?['projectId'];

      if (projectId != null) {
        final projectDoc =
            await _firestore.collection('projects').doc(projectId).get();
        final Map<String, dynamic>? projectData = projectDoc.data();
        final String? projectWorkerId = projectData?['workerId'];
        final String? projectOwnerId = projectData?['ownerId'];

        final recipientId =
            (role == 'owner') ? projectWorkerId : projectOwnerId;

        if (recipientId != null) {
          NotificationService().sendNotification(
            recipientId: recipientId,
            title: 'Contract Update',
            body:
                'The contract for your project has been accepted by the ${role}.',
            category: 'contract_accepted',
            data: {'projectId': projectId, 'contractId': contractId},
          );
        }
      }

      debugPrint("Contract accepted by $role: $contractId");
    } catch (e) {
      debugPrint("Accept Contract Error: $e");
      throw Exception("Failed to accept contract: $e");
    }
  }

  /// Get contract by contract ID
  Future<ContractTerms?> getContract(String contractId) async {
    try {
      final doc = await _firestore
          .collection('contracts')
          .doc(contractId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        return ContractTerms.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("Get Contract Error: $e");
      return null;
    }
  }

  /// Get contract by project ID
  Future<ContractTerms?> getContractByProjectId(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('projectId', isEqualTo: projectId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return ContractTerms.fromMap(doc.id, doc.data());
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
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId)
          .update({
        'status': MilestoneStatus.submitted.name,
        'submissionNote': note,
        'attachments': links,
        'submittedAt': Timestamp.now(),
      });

      // Trigger Notification
      final projectDoc =
          await _firestore.collection('projects').doc(projectId).get();
      final ownerId = projectDoc.data()?['ownerId'];
      if (ownerId != null) {
        NotificationService().sendNotification(
          recipientId: ownerId,
          title: 'Milestone Submitted',
          body: 'A milestone has been submitted for your review.',
          category: 'milestone_submitted',
          data: {'projectId': projectId, 'milestoneId': milestoneId},
        );
      }
    } catch (e) {
      throw Exception('Failed to submit work: $e');
    }
  }

  Future<void> approveMilestone(String projectId, String milestoneId) async {
    try {
      final projectRef = _firestore.collection('projects').doc(projectId);
      final milestoneRef = projectRef.collection('milestones').doc(milestoneId);

      await _firestore.runTransaction((transaction) async {
        final milestoneDoc = await transaction.get(milestoneRef);
        final projectDoc = await transaction.get(projectRef);

        if (!milestoneDoc.exists || !projectDoc.exists) {
          throw Exception('Milestone or Project not found');
        }

        final milestone =
            Milestone.fromMap(milestoneDoc.id, milestoneDoc.data()!);
        final projectData = projectDoc.data()!;
        final escrowBalance = (projectData['escrowBalance'] ?? 0.0).toDouble();
        final platformFeePercent =
            (projectData['platformFee'] ?? 0.0).toDouble();
        final workerId = projectData['workerId'] as String;
        final ownerId = projectData['ownerId'] as String;

        if (milestone.status != MilestoneStatus.submitted) {
          throw Exception('Milestone not in submitted state');
        }

        // Check escrow balance
        if (escrowBalance < milestone.amount) {
          throw Exception('Insufficient escrow balance');
        }

        // Calculate platform fee
        final feeAmount = milestone.amount * (platformFeePercent / 100);
        final totalMilestoneCost = milestone.amount + feeAmount;

        // 1. Update project escrow and statistics
        transaction.update(projectRef, {
          'escrowBalance': escrowBalance - totalMilestoneCost,
          'netEarnings': FieldValue.increment(
              milestone.amount), // Amount worker actually gets
          'platformFeeAccumulated':
              FieldValue.increment(feeAmount), // Track platform revenue
        });

        // 2. Update worker wallet
        final workerRef = _firestore.collection('users').doc(workerId);
        transaction.update(workerRef, {
          'pendingClearance': FieldValue.increment(-milestone.amount),
          'walletBalance':
              FieldValue.increment(milestone.amount), // Gets full amount
          'totalEarnings': FieldValue.increment(milestone.amount),
          'completedProjects': FieldValue.increment(0),
        });

        // 3. Update milestone status
        transaction.update(milestoneRef, {
          'status': MilestoneStatus.approved.name,
          'approvedAt': Timestamp.now(),
        });

        // 4. Create Transaction Record (Payout)
        final transactionRef = _firestore.collection('transactions').doc();
        final transactionData = {
          'projectId': projectId,
          'amount': milestone.amount, // Changed from netPayout
          'feeAmount': feeAmount,
          'totalAmount': totalMilestoneCost, // Changed from milestone.amount
          'type': 'payout',
          'description': 'Milestone Payout: ${milestone.title}',
          'timestamp': Timestamp.now(),
          'status': 'completed',
          'fromUserId': ownerId,
          'toUserId': workerId,
        };
        transaction.set(transactionRef, transactionData);

        // 5. Actually trigger backend payment release via API
        // NOTE: We do this after Firestore updates but it will be rolled back if the server call fails
        // because we are inside a transaction. Wait, actually Firestore transactions can't wait for HTTP.
        // Better to update Firestore first then call API.
      });

      // 6. Call Backend API for actual fund movement
      final projectDataDoc =
          await _firestore.collection('projects').doc(projectId).get();
      final milestoneDataDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId)
          .get();

      if (projectDataDoc.exists && milestoneDataDoc.exists) {
        final Map<String, dynamic> projData = projectDataDoc.data()!;
        final Map<String, dynamic> mileData = milestoneDataDoc.data()!;
        final double mileAmount = (mileData['amount'] ?? 0.0).toDouble();
        final String wId = projData['workerId'] as String;
        final String title = mileData['title'] as String;

        // Trigger Notification
        NotificationService().sendNotification(
          recipientId: wId,
          title: 'Milestone Approved',
          body: 'Your milestone "$title" has been approved!',
          category: 'milestone_approved',
          data: {'projectId': projectId, 'milestoneId': milestoneId},
        );

        // This method calls the Vercel backend to release the escrow funds to the worker
        await releasePayment(projectId, mileAmount);
        debugPrint(
            "Backend payment release triggered for milestone $milestoneId");
      }

      // 7. Check for project completion (Post-transaction)
      await _checkProjectCompletion(projectId);
    } catch (e) {
      debugPrint("Approve Milestone Error: $e");
      throw Exception('Failed to approve milestone: $e');
    }
  }

  Future<void> _checkProjectCompletion(String projectId) async {
    try {
      final projectRef = _firestore.collection('projects').doc(projectId);
      final projectDoc = await projectRef.get();
      if (!projectDoc.exists) return;

      final projectData = projectDoc.data()!;
      final milestoneIds =
          (projectData['milestoneIds'] as List?)?.cast<String>() ?? [];

      if (milestoneIds.isNotEmpty) {
        bool allApproved = true;
        for (final mId in milestoneIds) {
          final mDoc = await projectRef.collection('milestones').doc(mId).get();
          if (!mDoc.exists ||
              mDoc.data()?['status'] != MilestoneStatus.approved.name) {
            allApproved = false;
            break;
          }
        }

        if (allApproved) {
          await projectRef.update({
            'status': 'completed',
            'completedAt': Timestamp.now().millisecondsSinceEpoch,
            'progress': 1.0,
          });
        }
      }
    } catch (e) {
      debugPrint("Check Project Completion Error: $e");
    }
  }

  Future<void> updateMilestoneAgreedStatus(
    String projectId,
    String milestoneId,
    bool agreed,
  ) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId)
          .update({
        'workerAgreed': agreed,
        'workerAgreedAt': agreed ? Timestamp.now() : null,
      });
    } catch (e) {
      throw Exception('Failed to update milestone agreement: $e');
    }
  }

  Future<void> rejectMilestone(
      String projectId, String milestoneId, String reason) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId)
          .update({
        'status': MilestoneStatus.revisionRequested.name,
        'revisionNote': reason,
      });

      // Trigger Notification
      final projectDoc =
          await _firestore.collection('projects').doc(projectId).get();
      final workerId = projectDoc.data()?['workerId'];
      if (workerId != null) {
        NotificationService().sendNotification(
          recipientId: workerId,
          title: 'Milestone Rejected',
          body: 'A milestone requires revisions. Reason: $reason',
          category: 'milestone_rejected',
          data: {'projectId': projectId, 'milestoneId': milestoneId},
        );
      }
    } catch (e) {
      throw Exception('Failed to reject milestone: $e');
    }
  }

  // -------------------------
  // Withdrawal Management
  // -------------------------

  Future<void> requestWithdrawal(WithdrawalRequest request) async {
    final userRef = _firestore.collection('users').doc(request.userId);
    final withdrawalRef = _firestore.collection('withdrawals').doc(request.id);
    final transactionRef = _firestore.collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      // 1. Check user balance
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw Exception("User not found");

      final currentBalance =
          (userDoc.data()?['walletBalance'] ?? 0.0).toDouble();
      if (currentBalance < request.amount) {
        throw Exception("Insufficient balance for withdrawal");
      }

      // 2. Deduct balance
      transaction.update(userRef, {
        'walletBalance': FieldValue.increment(-request.amount),
      });

      // 3. Create withdrawal request
      transaction.set(withdrawalRef, request.toMap());

      // 4. Create transaction record
      final tx = transaction_model.Transaction(
        id: transactionRef.id,
        projectId: '',
        userId: request.userId,
        amount: request.amount,
        type: transaction_model.TransactionType.withdrawal,
        description:
            'Withdrawal Request: ${request.bankAccountName ?? 'Wallet'}',
        createdAt: DateTime.now(),
        status: transaction_model.TransactionStatus.pending,
      );
      transaction.set(transactionRef, tx.toMap());
    }).timeout(const Duration(seconds: 10));

    debugPrint("Withdrawal request $request.id submitted atomically");
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
      final docRef = _firestore.collection('ratings').doc();
      final ratingData = rating.toMap();

      await _firestore.runTransaction((transaction) async {
        // 1. Save the rating
        transaction.set(docRef, ratingData);

        // 2. Link it in the project document
        final projectRef =
            _firestore.collection('projects').doc(rating.projectId);
        final projectDoc = await transaction.get(projectRef);

        if (projectDoc.exists) {
          final isOwner = rating.raterRole == 'owner';
          transaction.update(projectRef, {
            isOwner ? 'ownerRatingId' : 'workerRatingId': docRef.id,
          });
        }

        // 3. Update the rated user's average rating (Optional/Future)
        // This could be move to Cloud Functions for better consistency
      });

      // Trigger Notification
      final projectDoc =
          await _firestore.collection('projects').doc(rating.projectId).get();
      final isOwnerRating = rating.raterRole == 'owner';
      final Map<String, dynamic>? projectData = projectDoc.data();
      String? recipientId;
      if (isOwnerRating) {
        recipientId = projectData?['workerId'];
      } else {
        recipientId = projectData?['ownerId'];
      }

      if (recipientId != null) {
        NotificationService().sendNotification(
          recipientId: recipientId,
          title: 'New Rating',
          body: 'You have received a new rating for your project.',
          category: 'new_rating',
          data: {'projectId': rating.projectId},
        );
      }

      debugPrint("Rating submitted successfully: ${docRef.id}");
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

  int _parseDurationInDays(String? timeline) {
    if (timeline == null || timeline.isEmpty) return 30; // Default

    // Try to find the first number in the string
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(timeline);
    if (match != null) {
      int value = int.parse(match.group(1)!);

      // If the string contains 'month', multiply by 30
      if (timeline.toLowerCase().contains('month')) {
        return value * 30;
      }
      // If the string contains 'week', multiply by 7
      if (timeline.toLowerCase().contains('week')) {
        return value * 7;
      }
      return value;
    }

    return 30; // Fallback
  }
}

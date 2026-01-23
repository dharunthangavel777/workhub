import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:work_hub/data/models/job_post_model.dart';
import 'package:work_hub/data/models/project_post_model.dart';
import 'package:work_hub/data/models/project_model.dart';
import 'package:work_hub/data/models/contract_terms_model.dart';
import 'package:work_hub/data/models/dispute_model.dart';
import 'package:work_hub/data/models/milestone_model.dart';
import 'package:work_hub/data/models/transaction_model.dart'
    as transaction_model;
import 'package:work_hub/data/models/withdrawal_request_model.dart';
import 'package:work_hub/data/models/rating_model.dart';
import 'package:work_hub/data/models/time_entry_model.dart';
import 'package:work_hub/data/repositories/job_repository.dart';
import 'package:work_hub/data/services/payment_service.dart';
import 'package:work_hub/data/services/widget_service.dart';

class JobProvider extends ChangeNotifier {
  final JobRepository _repository = JobRepository();

  List<JobPostModel> _jobPosts = [];
  List<ProjectPostModel> _projectPosts = [];
  List<JobPostModel> _myJobPosts = [];
  List<ProjectPostModel> _myProjectPosts = [];
  List<dynamic> _appliedPosts = [];
  Set<String> _appliedJobIds = {};
  Set<String> _appliedProjectIds = {};
  bool _isLoading = false;
  String _activeMode = 'job';
  String? _currentUserId;
  StreamSubscription? _jobPostsSubscription;
  StreamSubscription? _projectPostsSubscription;
  StreamSubscription? _myJobPostsSubscription;
  StreamSubscription? _myProjectPostsSubscription;
  StreamSubscription? _projectsSubscription;
  StreamSubscription? _applicationsSubscription;
  List<ProjectModel> _projects = [];

  // Contract and Transaction state
  ContractTerms? _currentContract;
  List<transaction_model.Transaction> _transactions = [];
  final PaymentService _paymentService = PaymentService();

  List<JobPostModel> get jobPosts => _jobPosts;
  List<ProjectPostModel> get projectPosts => _projectPosts;
  List<JobPostModel> get myJobPosts => _myJobPosts;
  List<ProjectPostModel> get myProjectPosts => _myProjectPosts;
  List<dynamic> get appliedJobs => _appliedPosts;
  Set<String> get appliedJobIds => _appliedJobIds;
  Set<String> get appliedProjectIds => _appliedProjectIds;
  List<ProjectModel> get projects => _projects;
  List<ProjectModel> get ongoingProjects => _projects.where((p) {
        if (p.status == 'active' ||
            p.status == 'disputed' ||
            p.status == 'setup') {
          return true;
        }
        if (p.status == 'completed' || p.status == 'cancelled') {
          // Keep in ongoing if completed less than 1 hour ago
          final completedTime = p.completedAt ?? 0;
          final oneHourAgo =
              DateTime.now().millisecondsSinceEpoch - (3600 * 1000);
          return completedTime > oneHourAgo;
        }
        return false;
      }).toList();

  List<ProjectModel> get archivedProjects => _projects.where((p) {
        if (p.status == 'completed' || p.status == 'cancelled') {
          // Only show in archive if completed more than 1 hour ago
          final completedTime = p.completedAt ?? 0;
          final oneHourAgo =
              DateTime.now().millisecondsSinceEpoch - (3600 * 1000);
          return completedTime <= oneHourAgo;
        }
        return false;
      }).toList();
  bool get isLoading => _isLoading;
  String get activeMode => _activeMode;
  ContractTerms? get currentContract => _currentContract;
  List<transaction_model.Transaction> get transactions => _transactions;

  // For backward compatibility while migration is in progress
  List<dynamic> get jobs => _activeMode == 'job' ? _jobPosts : _projectPosts;

  JobProvider() {
    _initJobs();
  }

  @override
  void dispose() {
    _jobPostsSubscription?.cancel();
    _projectPostsSubscription?.cancel();
    _myJobPostsSubscription?.cancel();
    _myProjectPostsSubscription?.cancel();
    _projectsSubscription?.cancel();
    _applicationsSubscription?.cancel();
    _milestoneSubscription?.cancel();
    _withdrawalSubscription?.cancel();
    super.dispose();
  }

  void _initJobs() {
    _jobPostsSubscription?.cancel();
    _projectPostsSubscription?.cancel();

    _jobPostsSubscription = _repository.getJobPostsStream().listen((list) {
      _jobPosts = list;
      notifyListeners();
      WidgetService.updateDashboardWidget(); // Live update for job count
    }, onError: (e) {
      debugPrint("Job Posts Stream Error: $e");
    });

    _projectPostsSubscription =
        _repository.getProjectPostsStream().listen((list) {
      _projectPosts = list;
      notifyListeners();
      WidgetService.updateDashboardWidget(); // Live update for freelance count
    }, onError: (e) {
      debugPrint("Project Posts Stream Error: $e");
    });
  }

  void listenToMyPosts(String userId) {
    _myJobPostsSubscription?.cancel();
    _myProjectPostsSubscription?.cancel();

    _myJobPostsSubscription =
        _repository.getOwnerJobPostsStream(userId).listen((list) {
      _myJobPosts = list;
      notifyListeners();
    }, onError: (e) {
      debugPrint("My Job Posts Stream Error: $e");
    });

    _myProjectPostsSubscription =
        _repository.getOwnerProjectPostsStream(userId).listen((list) {
      _myProjectPosts = list;
      notifyListeners();
    }, onError: (e) {
      debugPrint("My Project Posts Stream Error: $e");
    });
  }

  void updateMode(String mode) {
    if (_activeMode == mode) return;
    _activeMode = mode;
    _initJobs();
    if (_currentUserId != null) {
      listenToWorkerApplications(_currentUserId!);
    }
  }

  void listenToProjects(String userId, bool isOwner) {
    _currentUserId = userId;
    _projectsSubscription?.cancel();
    final stream = isOwner
        ? _repository.getOwnerProjectsStream(userId)
        : _repository.getWorkerProjectsStream(userId);

    _projectsSubscription = stream.listen((projectList) {
      _projects = projectList;
      notifyListeners();
      WidgetService
          .updateDashboardWidget(); // Trigger update on project changes
    }, onError: (e) {
      debugPrint("Projects Stream Error: $e");
    });
  }

  Future<void> createJobPost(JobPostModel job) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.postJob(job);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProjectPost(ProjectPostModel project) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.postProject(project);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> apply(String jobId, String userId, String workerName) async {
    await _repository.applyForJob(
        jobId,
        userId,
        {
          'workerName': workerName,
          'status': 'applied',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        _activeMode);
  }

  Future<void> updateApplicationStatus(
    String jobId,
    String userId,
    String status,
  ) async {
    await _repository.updateApplicationStatus(
      jobId,
      userId,
      status,
      _activeMode,
    );
  }

  void listenToWorkerApplications(String userId) {
    _currentUserId = userId;
    _applicationsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _applicationsSubscription = _repository
        .getWorkerApplicationsStream(userId, modeFilter: _activeMode)
        .listen((list) {
      debugPrint(
          "Received ${list.length} worker applications for mode $_activeMode");
      _appliedPosts = list;
      _appliedJobIds = list.whereType<JobPostModel>().map((p) => p.id).toSet();
      _appliedProjectIds =
          list.whereType<ProjectPostModel>().map((p) => p.id).toSet();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Worker Applications Stream Error: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> fetchWorkerApplications(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _appliedPosts = await _repository.getWorkerApplications(userId,
          modeFilter: _activeMode);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitBid({
    required String jobId,
    required String userId,
    required String workerName,
    required double bidAmount,
    required String proposal,
    required String deliveryTime,
    List<Map<String, dynamic>>? suggestedMilestones,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.submitBid(jobId, userId, {
        'workerName': workerName,
        'bidAmount': bidAmount,
        'proposal': proposal,
        'deliveryTime': deliveryTime,
        'suggestedMilestones': suggestedMilestones,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveBid({
    required String postId,
    required String workerId,
    required String workerName,
    required String title,
    required String description,
    required String ownerId,
    required String mode,
    double? bidAmount,
    double? depositAmount,
    String? termsAndConditions,
    List<dynamic>? suggestedMilestones,
    String? deliveryTime,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.approveBid(postId, workerId, {
        'jobId': postId,
        'workerId': workerId,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'mode': mode,
        'workerName': workerName,
        'budget': bidAmount,
        'depositAmount': depositAmount,
        'termsAndConditions': termsAndConditions,
        'suggestedMilestones': suggestedMilestones,
        'deliveryTime': deliveryTime,
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateProject(projectId, updates);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> releasePayment(String projectId, double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.releasePayment(projectId, amount);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateUser(userId, updates);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CONTRACT MANAGEMENT ==========

  /// Fetch contract by contract ID
  Future<void> fetchContract(String contractId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentContract = await _repository.getContract(contractId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch contract by project ID
  Future<void> fetchContractByProjectId(String projectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentContract = await _repository.getContractByProjectId(projectId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accept contract (by owner or worker)
  Future<void> acceptContract(
      String contractId, String userId, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.acceptContract(contractId, userId, role);
      // Refresh contract to show updated acceptance status
      await fetchContract(contractId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== ESCROW MANAGEMENT ==========

  /// Initiate escrow deposit via payment gateway
  Future<Map<String, dynamic>?> initiateEscrowDeposit({
    required String projectId,
    required double amount,
    required String userId,
    required String userEmail,
    required String userPhone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final orderId =
          'escrow_${projectId}_${DateTime.now().millisecondsSinceEpoch}';

      final paymentSessionId = await _paymentService.createOrder(
        orderId: orderId,
        amount: amount,
        customerId: userId,
        customerEmail: userEmail,
        customerPhone: userPhone,
        projectId: projectId,
        type: 'escrow_deposit',
      );

      return {
        'orderId': orderId,
        'paymentSessionId': paymentSessionId,
      };
    } catch (e) {
      debugPrint('Initiate Escrow Deposit Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start the actual payment flow (Mobile/Web)
  void startPaymentFlow({
    required String sessionId,
    required String orderId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) {
    _paymentService.startMobilePayment(sessionId, orderId, onSuccess, onError);
  }

  /// Confirm escrow deposit after successful payment
  Future<bool> confirmEscrowDeposit({
    required String projectId,
    required double amount,
    required String paymentSessionId,
    required String userId,
    required String orderId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Verify payment with payment gateway
      final isPaid = await _paymentService.verifyPayment(orderId);

      if (!isPaid) {
        debugPrint('Payment verification failed for order: $orderId');
        return false;
      }

      // Record escrow deposit
      await _repository.depositToEscrow(
        projectId: projectId,
        amount: amount,
        paymentSessionId: paymentSessionId,
        userId: userId,
      );

      debugPrint('Escrow deposit confirmed successfully');

      // Refresh transactions and project state
      await fetchTransactions(projectId);

      return true;
    } catch (e) {
      debugPrint('Confirm Escrow Deposit Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get escrow balance for a project
  Future<double> getEscrowBalance(String projectId) async {
    try {
      return await _repository.getEscrowBalance(projectId);
    } catch (e) {
      debugPrint('Get Escrow Balance Error: $e');
      return 0.0;
    }
  }

  // ========== TRANSACTION TRACKING ==========

  /// Fetch transaction history for a project
  Future<void> fetchTransactions(String projectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _repository.getTransactionHistory(projectId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record a transaction
  Future<String?> recordTransaction(
      transaction_model.Transaction transaction) async {
    try {
      final transactionId = await _repository.createTransaction(transaction);
      return transactionId;
    } catch (e) {
      debugPrint('Record Transaction Error: $e');
      return null;
    }
  }

  // ========== MILESTONE MANAGEMENT ==========

  List<Milestone> _milestones = [];
  StreamSubscription? _milestoneSubscription;

  List<Milestone> get milestones => _milestones;

  void listenToMilestones(String projectId) {
    _milestoneSubscription?.cancel();
    _milestoneSubscription =
        _repository.getMilestonesStream(projectId).listen((list) {
      _milestones = list;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Milestones Stream Error: $e");
    });
  }

  Future<void> createMilestone(String projectId, Milestone milestone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.createMilestone(projectId, milestone);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitMilestoneWork(
    String projectId,
    String milestoneId,
    String note,
    List<String> links,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.submitMilestoneWork(
          projectId, milestoneId, note, links);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveMilestone(String projectId, String milestoneId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.approveMilestone(projectId, milestoneId);
      // Refresh project to update escrow balance
      // Wait a bit to allow Firestore propagation
      await Future.delayed(const Duration(milliseconds: 500));
      // You might may need to re-fetch the project here if the stream doesn't update fast enough or if needed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncProjectProgress(String projectId) async {
    try {
      await _repository.syncProjectProgress(projectId);
    } catch (e) {
      debugPrint("Sync Progress Error: $e");
    }
  }

  Future<void> rejectMilestone(
      String projectId, String milestoneId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.rejectMilestone(projectId, milestoneId, reason);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMilestoneAgreedStatus(
    String projectId,
    String milestoneId,
    bool agreed,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateMilestoneAgreedStatus(
          projectId, milestoneId, agreed);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------
  // Withdrawal Management
  // -------------------------

  StreamSubscription? _withdrawalSubscription;
  List<WithdrawalRequest> _withdrawals = [];
  List<WithdrawalRequest> get withdrawals => _withdrawals;

  void listenToWithdrawals(String userId) {
    _withdrawalSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _withdrawalSubscription =
        _repository.getWithdrawalsStream(userId).listen((data) {
      _withdrawals = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to withdrawals: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> requestWithdrawal(WithdrawalRequest request) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.requestWithdrawal(request);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateWithdrawalStatus(
    String withdrawalId,
    WithdrawalStatus status, {
    String? failureReason,
    String? transactionId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.updateWithdrawalStatus(
        withdrawalId,
        status,
        failureReason: failureReason,
        transactionId: transactionId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // -------------------------
  // Dispute Management
  // -------------------------

  Future<void> raiseDispute(DisputeInfo dispute) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.raiseDispute(dispute);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Stream<List<DisputeInfo>> getDisputesStream(String projectId) {
    return _repository.getDisputesStream(projectId);
  }

  // -------------------------
  // Admin Methods
  // -------------------------

  Stream<List<WithdrawalRequest>> getPendingWithdrawalsStream() {
    return _repository.getPendingWithdrawalsStream();
  }

  Stream<List<DisputeInfo>> getAllDisputesStream() {
    return _repository.getAllDisputesStream();
  }

  // ========== FILE SHARING ==========

  Future<void> uploadFile({
    required String projectId,
    required File file,
    required String fileName,
    required String userId,
    required String userName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.uploadProjectFile(
        projectId: projectId,
        file: file,
        fileName: fileName,
        userId: userId,
        userName: userName,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFile({
    required String projectId,
    required Map<String, dynamic> fileMetadata,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteProjectFile(
        projectId: projectId,
        fileMetadata: fileMetadata,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== RATINGS & REVIEWS ==========

  Future<void> submitRating(Rating rating) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.submitRating(rating);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Rating?> getRatingById(String ratingId) async {
    return await _repository.getRatingById(ratingId);
  }

  Future<Rating?> getRatingByProjectAndRole(
      String projectId, String raterRole) async {
    return await _repository.getRatingByProjectAndRole(projectId, raterRole);
  }

  Stream<List<Rating>> getReviewsStream(String userId) {
    return _repository.getReviewsStream(userId);
  }

  // ========== TIME TRACKING ==========

  Future<void> logTime(String projectId, TimeEntry entry) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.logTimeEntry(projectId, entry);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<TimeEntry>> getTimeEntries(String projectId) {
    return _repository.getTimeEntriesStream(projectId);
  }

  Future<void> updateTimeEntryStatus(
    String projectId,
    String entryId,
    TimeEntryStatus status, {
    String? rejectionReason,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateTimeEntryStatus(
        projectId,
        entryId,
        status,
        rejectionReason: rejectionReason,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== SAVED JOBS & PROJECTS ==========

  Future<void> toggleSaveOpportunity({
    required String userId,
    required String opportunityId,
    required String type,
    required bool isSaving,
  }) async {
    await _repository.toggleSaveOpportunity(
      userId: userId,
      opportunityId: opportunityId,
      type: type,
      isSaving: isSaving,
    );
    notifyListeners();
  }

  Future<String> uploadDisputeFile({
    required String projectId,
    required File file,
    required String fileName,
  }) async {
    return await _repository.uploadDisputeFile(
      projectId: projectId,
      file: file,
      fileName: fileName,
    );
  }
}

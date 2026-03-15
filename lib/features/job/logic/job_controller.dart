import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:qwok/features/job/domain/models/job.dart';
import 'package:qwok/features/job/logic/job_filter_helper.dart';
import 'package:qwok/features/freelance/models/project.dart';
import 'package:qwok/features/common/contract/models/contract.dart';
import 'package:qwok/features/common/dispute/models/dispute.dart';
import 'package:qwok/features/freelance/models/milestone.dart';
import 'package:qwok/features/wallet/models/transaction.dart'
    as transaction_model;
import 'package:qwok/features/wallet/models/withdrawal_request.dart';
import 'package:qwok/features/profile/domain/models/rating.dart';
import 'package:qwok/features/freelance/models/time_entry.dart';
import 'package:qwok/features/job/data/job_repository.dart';
import 'package:qwok/features/freelance/data/project_repository.dart';
import 'package:qwok/features/common/contract/data/contract_repository.dart';
import 'package:qwok/features/job/data/milestone_repository.dart';
import 'package:qwok/features/wallet/data/wallet_repository.dart';
import 'package:qwok/features/profile/data/rating_repository.dart';
import 'package:qwok/core/services/widget_service.dart';
import 'package:qwok/core/storage/draft_repository.dart';
import 'package:qwok/core/orchestration/enterprise_state.dart';

class JobProvider extends ChangeNotifier
    with EnterpriseLogicMixin<List<dynamic>> {
  final JobRepository _jobRepository = JobRepository();
  final ProjectRepository _projectRepository = ProjectRepository();
  final ContractRepository _contractRepository = ContractRepository();
  final MilestoneRepository _milestoneRepository = MilestoneRepository();
  final WalletRepository _walletRepository = WalletRepository();
  final RatingRepository _ratingRepository = RatingRepository();
  final DraftRepository _draftRepository = DraftRepository();

  List<Job> _jobPosts = [];
  List<Job> _projectPosts = [];
  bool _isLoading = false;
  List<dynamic> _appliedPosts = [];
  bool _isApplying = false;
  String _activeMode = 'job';
  String? _currentUserId;
  StreamSubscription? _jobPostsSubscription;
  StreamSubscription? _projectPostsSubscription;
  StreamSubscription? _projectsSubscription;
  StreamSubscription? _applicationsSubscription;
  List<Project> _projects = [];

  // Advanced Filtered State
  List<Job> _filteredJobPosts = [];
  List<Job> _filteredProjectPosts = [];
  String _searchQuery = "";

  List<Job> get filteredJobPosts => _filteredJobPosts;
  List<Job> get filteredProjectPosts => _filteredProjectPosts;

  // Contract and Transaction state
  Contract? _currentContract;
  List<transaction_model.Transaction> _transactions = [];

  // State Orchestration
  EnterpriseState<List<Job>> _feedState = EnterpriseState.idle();
  EnterpriseState<List<Job>> get feedState => _feedState;

  EnterpriseState<List<dynamic>> _applicationsState = EnterpriseState.idle();
  EnterpriseState<List<dynamic>> get applicationsState => _applicationsState;

  bool get isLoading =>
      _isLoading ||
      _isApplying ||
      _feedState.status == UnifiedState.loading ||
      _applicationsState.status == UnifiedState.loading;
  List<Job> get jobPosts => _jobPosts;
  List<Job> get projectPosts => _projectPosts;
  List<dynamic> get appliedJobs => _appliedPosts.where((p) {
        if (p is Job) return p.postType == 'job';
        return false;
      }).toList();
  Set<String> get appliedJobIds =>
      appliedJobs.map((p) => (p as Job).id).toSet();
  Set<String> get appliedProjectIds =>
      appliedProjects.map((p) => (p as Job).id).toSet();
  List<dynamic> get appliedProjects => _appliedPosts.where((p) {
        if (p is Job) return p.postType == 'project';
        return false;
      }).toList();
  List<Project> get projects => _projects;
  List<Project> get ongoingProjects => _projects.where((p) {
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

  List<Project> get archivedProjects => _projects.where((p) {
        if (p.status == 'completed' || p.status == 'cancelled') {
          // Only show in archive if completed more than 1 hour ago
          final completedTime = p.completedAt ?? 0;
          final oneHourAgo =
              DateTime.now().millisecondsSinceEpoch - (3600 * 1000);
          return completedTime <= oneHourAgo;
        }
        return false;
      }).toList();
  String get activeMode => _activeMode;
  Contract? get currentContract => _currentContract;
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
    _projectsSubscription?.cancel();
    _applicationsSubscription?.cancel();
    _milestoneSubscription?.cancel();
    _withdrawalSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }

  void _initJobs() {
    _jobPostsSubscription?.cancel();
    _projectPostsSubscription?.cancel();

    _feedState = EnterpriseState.loading();
    notifyListeners();

    _jobPostsSubscription = _jobRepository.getJobPostsStream().listen((list) {
      _jobPosts = list;
      _checkFeedLoaded();
      WidgetService.updateDashboardWidget();
    }, onError: (e) {
      _feedState = EnterpriseState.error(e.toString());
      notifyListeners();
    });

    _projectPostsSubscription =
        _projectRepository.getProjectPostsStream().listen((list) {
      _projectPosts = list;
      _checkFeedLoaded();
      WidgetService.updateDashboardWidget();
    }, onError: (e) {
      _feedState = EnterpriseState.error(e.toString());
      notifyListeners();
    });
  }

  void updateSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  Future<void> _applyFilters() async {
    final query = _searchQuery;
    final appliedJobs = appliedJobIds;
    final appliedProjects = appliedProjectIds;

    // Use compute() to offload filtering to a background isolate
    // This is critical for keeping the UI thread at 144 FPS during typing/searching
    _filteredJobPosts = await compute(JobFilterHelper.filterJobsTask, {
      'posts': _jobPosts,
      'query': query,
      'appliedIds': appliedJobs,
    });

    _filteredProjectPosts = await compute(JobFilterHelper.filterJobsTask, {
      'posts': _projectPosts,
      'query': query,
      'appliedIds': appliedProjects,
    });

    notifyListeners();
  }

  void _checkFeedLoaded() {
    // Both are streams, so they will emit eventually.
    // We consider it "success" if we have data for the active mode at least.
    _applyFilters(); // Trigger filtering when data arrives
    _feedState = EnterpriseState.success(
        _activeMode == 'job' ? _jobPosts : _projectPosts);
    notifyListeners();
  }

  void updateMode(String mode) {
    if (_activeMode == mode) return;
    _activeMode = mode;
    _initJobs();
    if (_currentUserId != null) {
      listenToWorkerApplications(_currentUserId!);
    }
  }

  void listenToProjects(String userId) {
    _currentUserId = userId;
    _projectsSubscription?.cancel();
    final stream = _projectRepository.getWorkerProjectsStream(userId);

    _projectsSubscription = stream.listen((projectList) {
      _projects =
          projectList.map((m) => Project.fromMap(m['id'] ?? '', m)).toList();
      notifyListeners();
      WidgetService.updateDashboardWidget();
    }, onError: (e) {
      debugPrint("Projects Stream Error: $e");
    });
  }

  Future<void> apply({
    required dynamic post,
    required String userId,
    required String workerName,
    String? workerRole,
    String? workerAvatar,
  }) async {
    if (post == null) return;

    debugPrint("Applying for post: ${post.id} as $workerName ($workerRole)");
    final applicationData = {
      'workerName': workerName,
      'applicantName': workerName,
      'applicantRole': workerRole ?? "Professional",
      'applicantAvatar': workerAvatar,
      'status': 'applied',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ownerId': post.ownerId,
    };

    final submissionMode = post.postType == 'project' ? 'freelancer' : 'worker';

    // Optimistic UI Update: add the applied post immediately so the UI reflects it
    final Map<String, dynamic> currentApplicants =
        Map<String, dynamic>.from(post.applicants ?? {});
    currentApplicants[userId] = {
      'status': 'applied',
      'workerName': workerName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final updatedPost = post.copyWith(applicants: currentApplicants);
    _appliedPosts = [..._appliedPosts, updatedPost];
    _isApplying = true;
    notifyListeners();

    try {
      await _jobRepository.applyForJob(
          post.id, userId, applicationData, submissionMode);

      // Refresh the list from server to ensure sync
      try {
        final updatedList = await _jobRepository.getWorkerApplications(userId);
        // Only overwrite if the new application is actually present in the fetched list
        if (updatedList.any((p) => p is Job && p.id == post.id)) {
          _appliedPosts = updatedList;
        } else {
          // Keep the optimistic update
          debugPrint(
              "Application not yet in Firestore search, keeping optimistic entry for ${post.id}");
        }
      } catch (refreshError) {
        debugPrint("Background refresh failed after success: $refreshError");
        // We don't rollback here because the main action was successful
      }

      // Clear draft on success
      await _draftRepository.clearDraft(post.id);
      _isApplying = false;
      notifyListeners();
    } catch (e) {
      // Rollback on failure of the main action
      _appliedPosts =
          _appliedPosts.where((p) => p is Job && p.id != post.id).toList();
      _isApplying = false;
      notifyListeners();
      rethrow;
    }
  }

  // Draft Management
  Future<void> saveProposalDraft(
      String jobId, Map<String, dynamic> draft) async {
    await _draftRepository.saveDraft(jobId, draft);
  }

  Future<Map<String, dynamic>?> getProposalDraft(String jobId) async {
    return await _draftRepository.getDraft(jobId);
  }

  Future<void> updateApplicationStatus(
    String jobId,
    String userId,
    String status,
  ) async {
    await _jobRepository.updateApplicationStatus(
      jobId,
      userId,
      status,
      _activeMode,
    );
  }

  void listenToWorkerApplications(String userId) {
    _currentUserId = userId;
    _applicationsSubscription?.cancel();

    _applicationsState = EnterpriseState.loading();
    notifyListeners();

    _applicationsSubscription =
        _jobRepository.getWorkerApplicationsStream(userId).listen((list) {
      debugPrint("Received ${list.length} worker applications from stream");

      // Check if we have any optimistic updates that aren't in the server list yet
      final optimisticPosts = _appliedPosts.where((p) {
        if (p is! Job) return false;
        final bool isAlreadyInStream = list.any((s) => s.id == p.id);
        // We only keep it as optimistic if it's NOT in the stream AND we are currently applying
        return !isAlreadyInStream && _isApplying;
      }).toList();

      _appliedPosts = [...list, ...optimisticPosts];
      _applicationsState = EnterpriseState.success(_appliedPosts);
      notifyListeners();
    }, onError: (e) {
      debugPrint("Worker Applications Stream Error: $e");
      _applicationsState = EnterpriseState.error(e.toString());
      notifyListeners();
    });
  }

  Future<void> fetchWorkerApplications(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _appliedPosts = await _jobRepository.getWorkerApplications(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitBid({
    required Job jobPost,
    required String userId,
    required String workerName,
    required double bidAmount,
    required String proposal,
    required String deliveryTime,
    String? workerRole,
    String? workerAvatar,
    List<Map<String, dynamic>>? suggestedMilestones,
  }) async {
    final bidData = {
      'workerName': workerName,
      'applicantName': workerName,
      'applicantRole': workerRole ?? "Professional",
      'applicantAvatar': workerAvatar,
      'bidAmount': bidAmount,
      'proposal': proposal,
      'deliveryTime': deliveryTime,
      'suggestedMilestones': suggestedMilestones,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ownerId': jobPost.ownerId, // Pass ownerId so notifications work
    };

    // Optimistic UI Update for bid
    final updatedPost = jobPost.copyWith(
      applicants: {
        ...(jobPost.applicants ?? {}),
        userId: {
          'status': 'applied',
          'workerName': workerName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'bidAmount': bidAmount,
        }
      },
    );
    _appliedPosts = [..._appliedPosts, updatedPost];
    _isApplying = true;
    notifyListeners();

    try {
      await _jobRepository.submitBid(jobPost.id, userId, bidData);

      // Refresh applications list after successful bid
      try {
        final updatedList = await _jobRepository.getWorkerApplications(userId);

        if (updatedList.any((p) => p is Job && p.id == jobPost.id) ||
            _applicationsSubscription != null) {
          _appliedPosts = updatedList;
        } else {
          debugPrint(
              "Bid not yet in Firestore search, keeping optimistic entry for ${jobPost.id}");
        }
      } catch (refreshError) {
        debugPrint("Background refresh failed after success: $refreshError");
        // No rollback here
      }

      // Clear draft on success
      await _draftRepository.clearDraft(jobPost.id);
      _isApplying = false;
      notifyListeners();
    } catch (e) {
      // Rollback on main action failure
      _appliedPosts =
          _appliedPosts.where((p) => p is Job && p.id != jobPost.id).toList();
      _isApplying = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _projectRepository.updateProject(projectId, updates);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> releasePayment(String projectId, double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _jobRepository.releasePayment(projectId, amount);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> processDeposit(String projectId, double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _jobRepository.processDeposit(projectId, amount);
      // Wait a bit for Firestore sync or just rely on streams
      await Future.delayed(const Duration(seconds: 1));
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
      await _jobRepository.updateUser(userId, updates);
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
      _currentContract = await _contractRepository.getContract(contractId);
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
      _currentContract =
          await _contractRepository.getContractByProjectId(projectId);
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
      await _contractRepository.acceptContract(contractId, userId, role);
      // Refresh contract to show updated acceptance status
      await fetchContract(contractId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== ESCROW MANAGEMENT ==========

  /// Get escrow balance for a project
  Future<double> getEscrowBalance(String projectId) async {
    try {
      return await _contractRepository.getEscrowBalance(projectId);
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
      _transactions =
          await _walletRepository.getTransactionHistoryFuture(projectId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  StreamSubscription? _transactionsSubscription;
  void listenToTransactions(String userId) {
    _transactionsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _transactionsSubscription =
        _walletRepository.getTransactionsStreamForUser(userId).listen((data) {
      _transactions = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to transactions: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Record a transaction
  Future<String?> recordTransaction(
      transaction_model.Transaction transaction) async {
    try {
      await _walletRepository.createTransaction(transaction);
      return transaction.id;
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
        _milestoneRepository.getMilestonesStream(projectId).listen((list) {
      _milestones = list;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Milestones Stream Error: $e");
    });
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
      await _milestoneRepository.submitMilestoneWork(
          projectId, milestoneId, note, links);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectMilestone(
      String projectId, String milestoneId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _milestoneRepository.rejectMilestone(
          projectId, milestoneId, reason);
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
      await _milestoneRepository.updateMilestoneAgreedStatus(
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
        _walletRepository.getWithdrawalsStream(userId).listen((data) {
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
      await _walletRepository.requestWithdrawal(request);
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
      await _walletRepository.updateWithdrawalStatus(
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
      await _projectRepository.raiseDispute(dispute);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Stream<List<DisputeInfo>> getDisputesStream(String projectId) {
    return _projectRepository.getDisputesStream(projectId);
  }

  // -------------------------
  // Admin Methods
  // -------------------------

  Stream<List<WithdrawalRequest>> getPendingWithdrawalsStream() {
    return _walletRepository.getPendingWithdrawalsStream();
  }

  Stream<List<DisputeInfo>> getAllDisputesStream() {
    return _projectRepository.getAllDisputesStream();
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
      await _projectRepository.uploadProjectFile(
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
      await _projectRepository.deleteProjectFile(
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
      await _ratingRepository.submitRating(rating);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Rating?> getRatingById(String ratingId) async {
    return await _ratingRepository.getRatingById(ratingId);
  }

  Future<Rating?> getRatingByProjectAndRole(
      String projectId, String raterRole) async {
    return await _ratingRepository.getRatingByProjectAndRole(
        projectId, raterRole);
  }

  Stream<List<Rating>> getReviewsStream(String userId) {
    return _ratingRepository.getReviewsStream(userId);
  }

  // ========== TIME TRACKING ==========

  Future<void> logTime(String projectId, TimeEntry entry) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _projectRepository.logTimeEntry(projectId, entry);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<TimeEntry>> getTimeEntries(String projectId) {
    return _projectRepository.getTimeEntriesStream(projectId);
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
      await _projectRepository.updateTimeEntryStatus(
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
    await _jobRepository.toggleSaveOpportunity(
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
    return await _projectRepository.uploadDisputeFile(
      projectId: projectId,
      file: file,
      fileName: fileName,
    );
  }
}

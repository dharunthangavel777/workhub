import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Universal backend service that consolidates all API calls to the
/// centralized TypeScript payment-orchestrator backend.
class BackendService {
  // Set this to your deployed server URL or use an env variable via --dart-define
  static const String _baseUrl = String.fromEnvironment('BACKEND_URL',
      defaultValue: 'http://10.0.2.2:3000');

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
    };
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {String? idempotencyKey}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _getHeaders(idempotencyKey: idempotencyKey),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? data['error'] ?? 'Request failed');
    }
    return data;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _getHeaders(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? data['error'] ?? 'Request failed');
    }
    return data;
  }

  // ─── User ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> initializeUser() =>
      _post('/api/initializeUser', {});

  Future<Map<String, dynamic>> checkEligibility() =>
      _get('/api/checkEligibility');

  Future<Map<String, dynamic>> requestWithdrawal(double amount) =>
      _post('/api/requestWithdrawal', {'amount': amount});

  // ─── Project ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> approveBid(Map<String, dynamic> bidData) =>
      _post('/api/approveBid', bidData);

  Future<Map<String, dynamic>> applyForJob(
          String jobId, Map<String, dynamic> applicationData, String mode) =>
      _post('/api/applyForJob', {
        'jobId': jobId,
        'applicationData': applicationData,
        'mode': mode,
      });

  Future<Map<String, dynamic>> submitBid(
          String projectId, Map<String, dynamic> bidData) =>
      _post('/api/submitBid', {'projectId': projectId, 'bidData': bidData});

  Future<Map<String, dynamic>> completeProject(String projectId) =>
      _post('/api/completeProject', {'projectId': projectId});

  Future<Map<String, dynamic>> updateApplicationStatus(
          String jobId, String userId, String status, String mode) =>
      _post('/api/updateApplicationStatus', {
        'jobId': jobId,
        'targetUserId': userId,
        'status': status,
        'mode': mode,
      });

  Future<Map<String, dynamic>> submitMilestone(
          String projectId, String milestoneId,
          {String? note, List<String>? links}) =>
      _post('/api/submitMilestone', {
        'projectId': projectId,
        'milestoneId': milestoneId,
        'note': note,
        'links': links,
      });

  Future<Map<String, dynamic>> rejectMilestone(
          String projectId, String milestoneId, String reason) =>
      _post('/api/rejectMilestone', {
        'projectId': projectId,
        'milestoneId': milestoneId,
        'reason': reason,
      });

  Future<Map<String, dynamic>> agreeToMilestone(
          String projectId, String milestoneId, bool agreed) =>
      _post('/api/agreeToMilestone', {
        'projectId': projectId,
        'milestoneId': milestoneId,
        'agreed': agreed,
      });

  // ─── Rating ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitRating(String targetUserId, double rating,
          {String? projectId, String? review}) =>
      _post('/api/submitRating', {
        'targetUserId': targetUserId,
        'rating': rating,
        if (projectId != null) 'projectId': projectId,
        if (review != null) 'review': review,
      });

  // ─── Contract ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createContract({
    required String projectId,
    required double agreedBudget,
    required String paymentType,
    String? startDate,
    String? expectedCompletion,
  }) =>
      _post('/api/createContract', {
        'projectId': projectId,
        'agreedBudget': agreedBudget,
        'paymentType': paymentType,
        if (startDate != null) 'startDate': startDate,
        if (expectedCompletion != null)
          'expectedCompletion': expectedCompletion,
      });

  Future<Map<String, dynamic>> acceptContract(String contractId, String role) =>
      _post('/api/acceptContract', {'contractId': contractId, 'role': role});

  // ─── Payments (existing v3 routes) ───────────────────────────────────────

  Future<Map<String, dynamic>> createPaymentOrder(Map<String, dynamic> body) {
    final idempotencyKey = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    return _post('/v3/createOrder', body, idempotencyKey: idempotencyKey);
  }

  Future<Map<String, dynamic>> releaseFunds(Map<String, dynamic> body) =>
      _post('/v3/releaseFunds', body);

  Future<Map<String, dynamic>> addBeneficiary(Map<String, dynamic> body) {
    final idempotencyKey = 'bene_${DateTime.now().millisecondsSinceEpoch}';
    return _post('/v3/payouts/beneficiaries', body,
        idempotencyKey: idempotencyKey);
  }

  Future<Map<String, dynamic>> initiateWithdrawal(Map<String, dynamic> body) {
    final idempotencyKey = 'withdraw_${DateTime.now().millisecondsSinceEpoch}';
    return _post('/v3/payouts/withdraw', body, idempotencyKey: idempotencyKey);
  }
}

/// Singleton instance for convenience
final backendService = BackendService();




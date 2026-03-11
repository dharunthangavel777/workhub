import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:work_hub/core/constants/api_constants.dart';

class PaymentOrchestratorService {
  String get _baseUrl => ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Add Beneficiary
  Future<Map<String, dynamic>> addBeneficiary({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String bankAccount,
    required String ifsc,
    required String address,
    required String city,
    required String state,
    required String pincode,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Idempotency Key
      final idempotencyKey =
          'bene_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

      final response = await http.post(
        Uri.parse('$_baseUrl/payouts/beneficiaries'),
        headers: {
          ...(await _getHeaders()),
          'Idempotency-Key': idempotencyKey,
        },
        body: jsonEncode({
          'userId': userId,
          'name': name,
          'email': email,
          'phone': phone,
          'bankAccount': bankAccount,
          'ifsc': ifsc,
          'address': address,
          'city': city,
          'state': state,
          'pincode': pincode,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Add Beneficiary Failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Orchestrator AddBeneficiary Error: $e');
      rethrow;
    }
  }

  /// Initiate Withdrawal
  Future<Map<String, dynamic>> initiateWithdrawal({
    required String userId,
    required double amount,
    required String beneficiaryId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Idempotency Key
      final idempotencyKey =
          'withdraw_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

      final response = await http.post(
        Uri.parse('$_baseUrl/payouts/withdraw'),
        headers: {
          ...(await _getHeaders()),
          'Idempotency-Key': idempotencyKey,
        },
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'beneficiaryId': beneficiaryId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Withdrawal Failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Orchestrator Withdrawal Error: $e');
      rethrow;
    }
  }
}




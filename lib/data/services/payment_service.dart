import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// Direct imports as workaround for missing entry point in SDK 2.2.9+47
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';

// Use the standard conditional import pattern
import 'web_payment_stub.dart'
    if (dart.library.js_interop) 'web_payment_web.dart'
    if (dart.library.html) 'web_payment_web.dart';

/// PaymentService - Secure Payment Processing
class PaymentService {
  static const String _baseUrl = 'https://functions-kappa-gold.vercel.app';

  /// Helper to get authenticated headers
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Initialize User (Call this after sign-up)
  Future<void> initializeUser() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/initializeUser'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        debugPrint('⚠️ User initialization warning: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize user: $e');
    }
  }

  /// Create Payment Order (Secure)
  Future<String?> createOrder({
    required String orderId,
    required double amount,
    required String customerId,
    required String customerPhone,
    required String customerEmail,
    String? projectId,
    String? type,
  }) async {
    try {
      debugPrint('🔒 Creating secure payment order via API: $orderId');

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/createPaymentOrder'),
        headers: headers,
        body: jsonEncode({
          'orderId': orderId,
          'amount': amount,
          'customerId': customerId,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'projectId': projectId,
          'type': type,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('✅ Payment order created successfully');
        return data['paymentSessionId'] as String;
      } else {
        final errorMessage =
            data['message'] ?? 'Server error ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Payment order creation failed: $e');
      throw Exception('Failed to initiate payment: $e');
    }
  }

  /// Verify Payment Status (Secure)
  Future<bool> verifyPayment(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/verifyPaymentStatus'),
        headers: headers,
        body: jsonEncode({'orderId': orderId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 &&
          data['success'] == true &&
          data['isPaid'] == true;
    } catch (e) {
      debugPrint('❌ Payment verification failed: $e');
      return false;
    }
  }

  /// Start Mobile/Web Payment Flow
  void startMobilePayment(
    String sessionId,
    String orderId,
    Function(String) onSuccess,
    Function(String) onError,
  ) {
    if (kIsWeb) {
      try {
        debugPrint('🌐 Starting web payment');
        // triggerWebPayment is defined in your web_payment_web.dart and web_payment_stub.dart
        triggerWebPayment(sessionId, onSuccess, onError);
      } catch (e) {
        onError("Web payment error: $e");
      }
      return;
    }

    // Mobile implementation
    try {
      final cfSession = CFSessionBuilder()
          .setEnvironment(
              CFEnvironment.SANDBOX) // Change to .PRODUCTION for live
          .setOrderId(orderId)
          .setPaymentSessionId(sessionId)
          .build();

      final cfWebCheckout =
          CFWebCheckoutPaymentBuilder().setSession(cfSession).build();
      final cfPaymentGateway = CFPaymentGatewayService();

      cfPaymentGateway.setCallback(
        (orderId) => onSuccess(orderId),
        (cfErrorResponse, orderId) =>
            onError(cfErrorResponse.getMessage() ?? 'Payment failed'),
      );

      cfPaymentGateway.doPayment(cfWebCheckout);
    } catch (e) {
      onError(e.toString());
    }
  }
}

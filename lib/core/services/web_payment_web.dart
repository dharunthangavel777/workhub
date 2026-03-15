import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('Cashfree')
external dynamic get cashfree;

void triggerWebPayment(
    String sessionId, Function(String) onSuccess, Function(String) onError) {
  // Placeholder implementation
  debugPrint("Web payment initiated for session: $sessionId");
  // Actual implementation would involve calling cashfree.checkout({...})
}




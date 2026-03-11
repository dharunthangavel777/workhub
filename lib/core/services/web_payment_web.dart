import 'dart:js_interop';

@JS('Cashfree')
external dynamic get cashfree;

void triggerWebPayment(
    String sessionId, Function(String) onSuccess, Function(String) onError) {
  // Placeholder implementation
  print("Web payment initiated for session: $sessionId");
  // Actual implementation would involve calling cashfree.checkout({...})
}




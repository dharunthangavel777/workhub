import 'dart:js_interop';

@JS('triggerCashfreePayment')
external void _triggerCashfreePayment(JSString sessionId, JSString mode);

void triggerWebPayment(
  String paymentSessionId,
  Function(String) onSuccess,
  Function(String) onError,
) {
  try {
    // Call the global function we defined in index.html
    _triggerCashfreePayment(paymentSessionId.toJS, "sandbox".toJS);
  } catch (e) {
    onError(e.toString());
  }
}

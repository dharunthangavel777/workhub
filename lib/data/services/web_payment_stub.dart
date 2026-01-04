void triggerWebPayment(
  String paymentSessionId,
  Function(String) onSuccess,
  Function(String) onError,
) {
  // Desktop/Mobile default: Do nothing or error
  onError("Web payment not supported on this platform.");
}

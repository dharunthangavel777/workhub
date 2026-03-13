import 'dart:async';
import 'package:flutter/material.dart';
import 'package:work_hub/features/common/widgets/custom_toast.dart';
import 'package:work_hub/main.dart';

class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  OverlayEntry? _currentEntry;
  Timer? _timer;

  void show({
    required ToastType type,
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    _currentEntry?.remove();
    _timer?.cancel();

    _currentEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        type: type,
        title: title,
        message: message,
        onDismiss: () => dismiss(),
        onRetry: onRetry != null 
          ? () {
              dismiss();
              onRetry();
            }
          : null,
      ),
    );

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay != null) {
      overlay.insert(_currentEntry!);
      _timer = Timer(duration, () => dismiss());
    }
  }

  void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _timer?.cancel();
  }

  // Helper methods
  void showSuccess(String title, {String? message}) {
    show(type: ToastType.success, title: title, message: message);
  }

  void showError(String title, {String? message, VoidCallback? onRetry}) {
    show(
      type: ToastType.error, 
      title: title, 
      message: message, 
      duration: const Duration(seconds: 5),
      onRetry: onRetry,
    );
  }

  void showWarning(String title, {String? message}) {
    show(type: ToastType.warning, title: title, message: message);
  }

  void showInfo(String title, {String? message}) {
    show(type: ToastType.info, title: title, message: message);
  }
}

class _ToastOverlay extends StatefulWidget {
  final ToastType type;
  final String title;
  final String? message;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  const _ToastOverlay({
    required this.type,
    required this.title,
    this.message,
    required this.onDismiss,
    this.onRetry,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: CustomToast(
                type: widget.type,
                title: widget.title,
                message: widget.message,
                onDismiss: widget.onDismiss,
                onRetry: widget.onRetry,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

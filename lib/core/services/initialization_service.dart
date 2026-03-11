import 'package:flutter/material.dart';
import 'package:work_hub/core/services/notification_service.dart';

class AppInitializationService extends ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _error;
  String? get error => _error;

  Future<void> initialize(BuildContext context) async {
    try {
      // Core services (Firebase, Supabase, Dotenv) are now initialized in main()
      // to prevent "NotInitializedError" in Providers.

      // 1. Secondary initializations
      await Future.wait([
        NotificationService().initialize(),
        _prewarmAssets(context),
      ]);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _prewarmAssets(BuildContext context) async {
    // Precache critical images to avoid flicker
    if (!context.mounted) return;

    await Future.wait([
      precacheImage(const AssetImage('assets/icons/app.png'), context),
      precacheImage(const AssetImage('assets/images/1.gif'), context),
      precacheImage(const AssetImage('assets/images/2.gif'), context),
      precacheImage(const AssetImage('assets/images/3.gif'), context),
    ]);
  }
}

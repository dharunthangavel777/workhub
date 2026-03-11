import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // If any valid connection is available, we're online.
    final hasConnection = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);

    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      debugPrint(
          "🌐 Connectivity Changed: Online = $_isOnline (Results: $results)");
      notifyListeners();
    }
  }

  Future<void> checkStatus() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}




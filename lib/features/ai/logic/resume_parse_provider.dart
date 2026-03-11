import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/resume_data_model.dart';
import '../domain/models/resume_score_model.dart';
import '../data/resume_api_service.dart';
import '../data/socket_service.dart';

enum ResumeParseStatus {
  idle,
  extractingText,
  uploading,
  processing,
  done,
  error
}

class ResumeParseProvider extends ChangeNotifier {
  final ResumeApiService _apiService = ResumeApiService();
  final SocketService _socketService = SocketService();

  ResumeParseStatus _status = ResumeParseStatus.idle;
  ResumeParseStatus get status => _status;

  String? _error;
  String? get error => _error;

  ResumeData? _parsedData;
  ResumeData? get parsedData => _parsedData;

  ResumeScore? _score;
  ResumeScore? get score => _score;

  String? _jobId;
  Timer? _pollingTimer;

  void reset() {
    debugPrint('ResumeParseProvider: Resetting state');
    _status = ResumeParseStatus.idle;
    _error = null;
    _parsedData = null;
    _score = null;
    _jobId = null;
    stopPolling();
    notifyListeners();
  }

  void setExtractingStatus() {
    _status = ResumeParseStatus.extractingText;
    _error = null;
    notifyListeners();
  }

  Future<void> submitResume(String resumeText) async {
    _status = ResumeParseStatus.uploading;
    _error = null;
    notifyListeners();
    debugPrint(
        'ResumeParseProvider: Submitting resume text (len: ${resumeText.length})');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        _status = ResumeParseStatus.error;
        notifyListeners();
        return;
      }

      // 1. Submit to Backend
      _jobId = await _apiService.parseResume(resumeText: resumeText);
      debugPrint('ResumeParseProvider: Job ID received: $_jobId');

      if (_jobId != null) {
        _status = ResumeParseStatus.processing;
        notifyListeners();

        // 2. Setup WebSocket for real-time result
        debugPrint('ResumeParseProvider: Connecting socket for ${user.uid}');
        _socketService.connect(user.uid);
        _socketService.onResumeDone((data) {
          debugPrint('ResumeParseProvider: Received data from WebSocket');
          _handleCompletion(data);
        });

        // 3. Fallback: Start polling in case WebSocket fails
        startPolling();
      } else {
        _error = 'Failed to initiate parsing. Please try again.';
        _status = ResumeParseStatus.error;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ResumeParseProvider Error: $e');
      _error = 'Processing failed: ${e.toString()}';
      _status = ResumeParseStatus.error;
      notifyListeners();
    }
  }

  void _handleCompletion(Map<String, dynamic> data) {
    if (_status == ResumeParseStatus.done) return;

    _parsedData = ResumeData.fromJson({'parsedData': data});
    _score = ResumeScore.fromJson(data);
    _status = ResumeParseStatus.done;
    stopPolling();
    _socketService.disconnect();
    notifyListeners();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_jobId == null) return;

      final jobStatus = await _apiService.getJobStatus(_jobId!);
      if (jobStatus != null && jobStatus['state'] == 'completed') {
        _handleCompletion(jobStatus['result']);
      } else if (jobStatus != null && jobStatus['state'] == 'failed') {
        _error = jobStatus['failReason'] ?? 'Job failed on server';
        _status = ResumeParseStatus.error;
        stopPolling();
        notifyListeners();
      }
    });

    // Auto-timeout polling after 1 minute
    Timer(const Duration(minutes: 1), () {
      if (_status == ResumeParseStatus.processing) {
        stopPolling();
        // Maybe try local fallback if still processing
        if (_parsedData == null) {
          _error = 'Server processing timed out.';
          _status = ResumeParseStatus.error;
          notifyListeners();
        }
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    _socketService.disconnect();
    super.dispose();
  }
}




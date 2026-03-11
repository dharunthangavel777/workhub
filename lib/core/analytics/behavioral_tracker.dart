import 'dart:async';
import 'package:flutter/foundation.dart';

/// Module for tracking user behavior (Scroll, Dwell time)
/// Part of Phase 5: Predictive & AI Layer
class BehavioralTracker {
  static final BehavioralTracker _instance = BehavioralTracker._internal();
  factory BehavioralTracker() => _instance;
  BehavioralTracker._internal();

  final Map<String, _DwellSession> _activeSessions = {};

  // Streams for intent prediction
  final _intentController = StreamController<BehavioralIntent>.broadcast();
  Stream<BehavioralIntent> get intentStream => _intentController.stream;

  void onDwellStart(String entityId, String type) {
    if (_activeSessions.containsKey(entityId)) return;

    _activeSessions[entityId] = _DwellSession(
      id: entityId,
      type: type,
      startTime: DateTime.now(),
    );
    debugPrint('BEHAVIOR: Dwell start on $type:$entityId');
  }

  void onDwellEnd(String entityId) {
    final session = _activeSessions.remove(entityId);
    if (session == null) return;

    final duration = DateTime.now().difference(session.startTime);
    debugPrint(
        'BEHAVIOR: Dwell end on ${session.type}:$entityId. Duration: ${duration.inSeconds}s');

    // If dwelt for more than 3 seconds, emit 'High Interest' intent
    if (duration.inSeconds >= 3) {
      _intentController.add(BehavioralIntent(
        entityId: entityId,
        type: session.type,
        intentLevel: IntentLevel.highInterest,
      ));
    }
  }

  void onScrollEvent(String context, double offset) {
    // Basic tracking of scroll depth
    // Potential to predict intent based on rapid scrolling vs slow reading
  }

  void dispose() {
    _intentController.close();
  }
}

class _DwellSession {
  final String id;
  final String type;
  final DateTime startTime;

  _DwellSession(
      {required this.id, required this.type, required this.startTime});
}

enum IntentLevel { low, medium, highInterest }

class BehavioralIntent {
  final String entityId;
  final String type;
  final IntentLevel intentLevel;

  BehavioralIntent({
    required this.entityId,
    required this.type,
    required this.intentLevel,
  });
}




import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AICacheService {
  static const String _keyMatches = 'ai_matches_cache';
  static const String _keyTimestamp = 'ai_matches_timestamp';
  static const Duration _cacheDuration = Duration(hours: 24);

  // Singleton pattern
  static final AICacheService _instance = AICacheService._internal();
  factory AICacheService() => _instance;
  AICacheService._internal();

  /// Save matches with current timestamp
  Future<void> saveMatches(List<Map<String, dynamic>> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final String matchesJson = json.encode(matches);
    await prefs.setString(_keyMatches, matchesJson);
    await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached matches if valid (< 24 hrs)
  /// Returns null if cache is expired or empty
  Future<List<Map<String, dynamic>>?> getValidMatches() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if data exists
    if (!prefs.containsKey(_keyMatches) || !prefs.containsKey(_keyTimestamp)) {
      return null;
    }

    // Check expiration
    final int? timestamp = prefs.getInt(_keyTimestamp);
    if (timestamp == null) return null;

    final DateTime savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();

    if (now.difference(savedTime) > _cacheDuration) {
      // Cache expired
      await clearCache();
      return null;
    }

    // Load data
    final String? matchesJson = prefs.getString(_keyMatches);
    if (matchesJson == null) return null;

    try {
      final List<dynamic> decoded = json.decode(matchesJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      // Corrupt data
      await clearCache();
      return null;
    }
  }

  /// Get time remaining until next refresh is available
  Future<Duration> getTimeRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_keyTimestamp);
    if (timestamp == null) return Duration.zero;

    final DateTime savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime expiryTime = savedTime.add(_cacheDuration);
    final DateTime now = DateTime.now();

    if (now.isAfter(expiryTime)) return Duration.zero;
    return expiryTime.difference(now);
  }

  /// Clear the cache manually
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMatches);
    await prefs.remove(_keyTimestamp);
  }
}




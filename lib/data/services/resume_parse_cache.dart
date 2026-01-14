import 'dart:io';
import '../models/resume_data_model.dart';

/// Simple in-memory cache for parsed resumes
class ResumeParseCache {
  static final Map<String, ResumeData> _cache = {};
  static const int maxCacheSize = 10;

  /// Generate unique key for file based on path, size, and modification time
  static String _getFileHash(File file) {
    try {
      final path = file.path;
      final size = file.lengthSync();
      final modified = file.lastModifiedSync().millisecondsSinceEpoch;
      return '$path\_$size\_$modified';
    } catch (e) {
      // If we can't get file info, just use path
      return file.path;
    }
  }

  /// Get cached resume data for a file
  static ResumeData? get(File file) {
    final key = _getFileHash(file);
    return _cache[key];
  }

  /// Cache resume data for a file
  static void set(File file, ResumeData data) {
    final key = _getFileHash(file);

    // Add to cache
    _cache[key] = data;

    // Keep cache size manageable (FIFO eviction)
    if (_cache.length > maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
  }

  /// Clear all cached data
  static void clear() {
    _cache.clear();
  }

  /// Check if file is cached
  static bool has(File file) {
    final key = _getFileHash(file);
    return _cache.containsKey(key);
  }
}

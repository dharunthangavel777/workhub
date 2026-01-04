import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  /// Saves a file to the application's documents directory under the specified subPath.
  /// Returns the absolute path of the saved file.
  Future<String?> saveFile(File file, String subPath) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final targetPath = p.join(appDocDir.path, subPath);

      final targetFile = File(targetPath);
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }

      final savedFile = await file.copy(targetPath);
      debugPrint("Local Storage: File saved to ${savedFile.path}");
      return savedFile.path;
    } catch (e) {
      debugPrint("Local Storage Error: $e");
      return null;
    }
  }

  /// Returns a File object from a local path.
  File getFile(String path) {
    return File(path);
  }

  /// Checks if a path is a local file path.
  bool isLocalPath(String path) {
    return path.startsWith('/') ||
        path.contains(':\\'); // Handles Android/iOS and Windows paths
  }
}

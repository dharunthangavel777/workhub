import 'dart:io';
import 'package:flutter/material.dart';

class ImageUtils {
  static ImageProvider getImageProvider(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage('assets/images/placeholder_user.png');
    }

    if (path.startsWith('/') ||
        path.contains(':\\') ||
        path.contains('/data/user/')) {
      return FileImage(File(path));
    }

    return NetworkImage(path);
  }

  static bool isLocalPath(String? path) {
    if (path == null) return false;
    return path.startsWith('/') ||
        path.contains(':\\') ||
        path.contains('/data/user/');
  }
}

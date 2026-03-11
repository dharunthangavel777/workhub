import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  SupabaseClient get _supabase => Supabase.instance.client;
  static const String _bucket = 'work-hub';

  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    try {
      final path =
          'users/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from(_bucket).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint("Supabase Storage Error (Profile): $e");
      return null;
    }
  }

  Future<String?> uploadPortfolioItem(
    String uid,
    String fileName,
    File imageFile,
  ) async {
    try {
      final path = 'users/$uid/portfolio/$fileName.jpg';
      await _supabase.storage.from(_bucket).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint("Supabase Storage Error (Portfolio): $e");
      return null;
    }
  }

  Future<String?> uploadFile(String path, File file) async {
    try {
      await _supabase.storage.from(_bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint("Supabase Storage Error (uploadFile): $e");
      return null;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _supabase.storage.from(_bucket).remove([path]);
    } catch (e) {
      debugPrint("Supabase Storage Error (deleteFile): $e");
    }
  }
}




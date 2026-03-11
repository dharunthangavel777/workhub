import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftRepository {
  static const String _prefix = 'draft_';

  Future<void> saveDraft(String id, Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$id', jsonEncode(draft));
  }

  Future<Map<String, dynamic>?> getDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_prefix$id');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$id');
  }
}




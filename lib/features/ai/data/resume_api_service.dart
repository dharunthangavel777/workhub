import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:qwok/core/constants/api_constants.dart';

class ResumeApiService {
  static String get baseUrl => ApiConstants.apiBaseUrl;

  Future<String?> parseResume({
    required String resumeText,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final token = await user.getIdToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/resume/parse'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'resumeText': resumeText,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('ResumeParse SUCCESS: jobId=${data['jobId']}');
        return data['jobId'];
      } else {
        debugPrint(
            'Parse API Error: ${response.statusCode} - ${data['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('ResumeApiService Exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getJobStatus(String jobId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/resume/job/$jobId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data; // returns { success, jobId, state, result, failReason }
      } else {
        debugPrint('Job Status API Error: ${data['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('ResumeApiService JobStatus Exception: $e');
      return null;
    }
  }
}




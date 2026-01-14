import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/resume_data_model.dart';

class LocalParserService {
  // Local server URL (default FastAPI port 8000)
  // Use 10.0.2.2 for Android emulator to hit localhost
  // Use 10.0.2.2 for Android emulator, or your local machine IP for physical devices
  final String _baseUrl = kDebugMode
      ? 'http://10.58.172.61:8000' // Your machine's local IP address
      : 'http://localhost:8000';

  Future<ResumeData?> parseResume(File file) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/parse'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(responseData);
        if (result['success'] == true) {
          // Wrap the extracted data in the expected structure for for ResumeData.fromJson
          final Map<String, dynamic> formattedData = {
            "parsedData": result['data']
          };
          return ResumeData.fromJson(formattedData);
        }
      } else {
        debugPrint(
            'Local Parser Error: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      debugPrint('Local Parser Connection Error: $e');
    }
    return null;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OcrService {
  static final String _apiKey = dotenv.env['OCR_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.ocr.space/parse/image';

  static Future<String> extractText(File imageFile) async {
    if (_apiKey.isEmpty) {
      debugPrint('OCR_API_KEY is empty. Please check your .env file.');
      return '';
    }

    try {
      debugPrint('Sending image to OCR.space...');

      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.fields['apikey'] = _apiKey;
      request.fields['language'] = 'eng';
      request.fields['isOverlayRequired'] = 'false';
      request.fields['FileType'] = imageFile.path.split('.').last.toLowerCase();

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['IsErroredOnProcessing'] == true) {
          debugPrint('OCR Error: ${data['ErrorMessage']}');
          return '';
        }

        final List<dynamic> parsedResults = data['ParsedResults'] ?? [];
        if (parsedResults.isNotEmpty) {
          final String text = parsedResults[0]['ParsedText'] ?? '';
          debugPrint('OCR Text Extracted Successfully (${text.length} chars)');
          return text;
        }
      } else {
        debugPrint('OCR API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error during OCR extraction: $e');
    }
    return '';
  }
}

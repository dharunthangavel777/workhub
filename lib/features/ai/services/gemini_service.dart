import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../domain/models/resume_data_model.dart';

class GeminiService {
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  GenerativeModel? _model;

  GenerativeModel _getModel() {
    return _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
    );
  }

  Future<ResumeData?> parseResume(String text) async {
    if (_apiKey.isEmpty) {
      debugPrint('GEMINI_API_KEY is empty. Please check your .env file.');
      return null;
    }

    try {
      debugPrint('Parsing resume using Gemini AI...');

      final prompt = '''
      You are a professional resume parser. You must analyze the provided resume text and extract all relevant information.
      Return the data strictly in the following JSON format. Do not include any text outside the JSON block.
      
      Resume Text:
      $text
      
      Output Format (JSON):
      {
        "name": "Candidate's Full Name",
        "email": "Candidate's Email",
        "phone": "Candidate's Phone",
        "location": "City, State/Country",
        "bio": "A professional summary (2-3 sentences max)",
        "category": "Main job title or category (e.g. Flutter Developer, Graphic Designer)",
        "skills": ["Skill 1", "Skill 2", ...],
        "education": [
          {"degree": "Degree Name", "institution": "School Name", "year": "Year"}
        ],
        "workExperience": [
          {"title": "Role Name", "company": "Company Name", "duration": "Dates", "description": "Key responsibilities"}
        ],
        "projects": [
          {"title": "Project Title", "description": "Brief project description"}
        ],
        "certifications": [
          {"name": "Cert Name", "issuer": "Issuer", "date": "Date"}
        ]
      }
      ''';

      final content = [Content.text(prompt)];
      final response = await _getModel().generateContent(content);

      if (response.text != null) {
        String jsonStr = response.text!.trim();

        // More robust JSON extraction
        final jsonRegex = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegex.stringMatch(jsonStr);
        if (match != null) {
          jsonStr = match;
        }

        final Map<String, dynamic> parsedJson = jsonDecode(jsonStr);

        return ResumeData.fromJson(
            {"parsedData": parsedJson, "confidenceScores": {}});
      }
    } catch (e) {
      debugPrint("Gemini Parsing Error: $e");
      return null;
    }
    return null;
  }
}




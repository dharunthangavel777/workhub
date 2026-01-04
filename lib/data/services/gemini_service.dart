import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/resume_data_model.dart';

class GeminiService {
  late final GenerativeModel _model;
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<ResumeData?> parseResume(String text) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception("Gemini API Key is missing in .env");
      }

      final prompt = '''
      You are an expert resume parser. Extract information from the following resume text and return it in a structured JSON format.
      
      The JSON structure should be:
      {
        "parsedData": {
          "name": "Full Name",
          "email": "Email Address",
          "phone": "Phone Number",
          "location": "City, Country",
          "bio": "A brief professional summary",
          "category": "Primary job category (e.g., Mobile Developer, Backend, Designer)",
          "education": [
            { "degree": "Degree Name", "institution": "University Name", "year": "Graduation Year" }
          ],
          "skills": ["Skill 1", "Skill 2"],
          "projects": [
            { "title": "Project Name", "description": "Project Summary", "techStack": ["Tag 1", "Tag 2"] }
          ],
          "workExperience": [
            { "title": "Job Title", "company": "Company Name", "duration": "Start - End", "description": "Responsibilities" }
          ]
        },
        "confidenceScores": {
          "name": 0.95,
          "email": 0.9,
          "location": 0.8,
          "education": 0.85,
          "skills": 0.9,
          "projects": 0.75
        }
      }

      Resume Text:
      $text
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) return null;

      final Map<String, dynamic> jsonResponse = jsonDecode(response.text!);
      return ResumeData.fromJson(jsonResponse);
    } catch (e) {
      debugPrint("Gemini Parsing Error: $e");
      return null;
    }
  }

  Future<ResumeData?> parseResumeFromImage(
      Uint8List imageBytes, String mimeType) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception("Gemini API Key is missing in .env");
      }

      final prompt = '''
      You are an expert resume parser. Extract information from the provided resume image and return it in a structured JSON format.
      
      The JSON structure should be:
      {
        "parsedData": {
          "name": "Full Name",
          "email": "Email Address",
          "phone": "Phone Number",
          "location": "City, Country",
          "bio": "A brief professional summary",
          "category": "Primary job category (e.g., Mobile Developer, Backend, Designer)",
          "education": [
            { "degree": "Degree Name", "institution": "University Name", "year": "Graduation Year" }
          ],
          "skills": ["Skill 1", "Skill 2"],
          "projects": [
            { "title": "Project Name", "description": "Project Summary", "techStack": ["Tag 1", "Tag 2"] }
          ],
          "workExperience": [
            { "title": "Job Title", "company": "Company Name", "duration": "Start - End", "description": "Responsibilities" }
          ]
        },
        "confidenceScores": {
          "name": 0.95,
          "email": 0.9,
          "location": 0.8,
          "education": 0.85,
          "skills": 0.9,
          "projects": 0.75
        }
      }
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);

      if (response.text == null) return null;

      final Map<String, dynamic> jsonResponse = jsonDecode(response.text!);
      return ResumeData.fromJson(jsonResponse);
    } catch (e) {
      debugPrint("Gemini Image Parsing Error: $e");
      return null;
    }
  }
}

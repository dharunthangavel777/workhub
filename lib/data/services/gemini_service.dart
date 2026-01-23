import 'package:flutter/foundation.dart';
import '../models/resume_data_model.dart';
// import 'ocr_service.dart'; // Not directly used here, but Logic calls it.

class GeminiService {
  // 100% Local Rule-Based Resume Parser

  Future<ResumeData?> parseResume(String text) async {
    try {
      debugPrint('Parsing resume locally (Enhanced Logic)...');

      // 1. Basic Info
      final email = _extractEmail(text);
      final phone = _extractPhone(text);
      final name = _extractName(text, email);
      final bio = _summarizeText(text, maxSentences: 3);

      // 2. Skills
      final skills = _extractSkills(text);

      // 3. Category
      final category = _determineCategory(text, skills);

      // 4. Complex Sections (Experience & Education)
      final workExperience = _extractWorkExperience(text);
      final education = _extractEducation(text);

      // 5. Projects (Basic extraction)
      final projects = _extractProjects(text);

      final Map<String, dynamic> parsedDataMap = {
        "name": name,
        "email": email,
        "phone": phone,
        "location": "",
        "bio": bio,
        "category": category,
        "education": education.map((e) => e.toJson()).toList(),
        "skills": skills,
        "projects": projects.map((p) => p.toJson()).toList(),
        "workExperience": workExperience.map((w) => w.toJson()).toList()
      };

      final Map<String, dynamic> confidenceScores = {
        "name": name.isNotEmpty ? 0.8 : 0.0,
        "email": email.isNotEmpty ? 1.0 : 0.0,
        "location": 0.0,
        "education": education.isNotEmpty ? 0.5 : 0.0,
        "skills": skills.isNotEmpty ? 0.9 : 0.0,
        "projects": projects.isNotEmpty ? 0.6 : 0.0,
        "workExperience": workExperience.isNotEmpty ? 0.7 : 0.0,
      };

      final Map<String, dynamic> fullJson = {
        "parsedData": parsedDataMap,
        "confidenceScores": confidenceScores
      };

      return ResumeData.fromJson(fullJson);
    } catch (e) {
      debugPrint("Local Parsing Error: $e");
      return null;
    }
  }

  // Same logic for image: caller should have OCR'd it.
  Future<ResumeData?> parseResumeFromImage(
      Uint8List imageBytes, String mimeType) async {
    // This service expects text. The LocalParserService handles OCR.
    // If we somehow get here without text, valid behavior is to return null or throw.
    return null;
  }

  // --- Helper Methods ---

  String _extractEmail(String text) {
    final emailRegex = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b');
    final match = emailRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractPhone(String text) {
    // Regex matches common formats: +1-555-555-5555, (555) 555-5555, 555 555 5555
    final phoneRegex =
        RegExp(r'\b[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}\b');
    final match = phoneRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractName(String text, String email) {
    // Heuristic: Name is usually on the first non-empty line.
    // We try to clean it up (remove common header words if any).
    final lines = text.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Skip if it looks like an email or phone or specific header
      if (trimmed.length > 50) continue; // Too long for a name usually
      if (trimmed.contains('@')) continue;
      if (trimmed.contains(RegExp(r'[0-9]')))
        continue; // Name usually has no numbers
      if (['resume', 'curriculum', 'vitae', 'cv', 'profile']
          .contains(trimmed.toLowerCase())) continue;

      // Capitalize first letters
      return trimmed.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    // Fallback: use email username part
    if (email.isNotEmpty) {
      return email.split('@')[0];
    }
    return "Candidate";
  }

  List<String> _extractSkills(String text) {
    // A list of common tech skills to look for
    final commonSkills = [
      'flutter',
      'dart',
      'python',
      'java',
      'javascript',
      'typescript',
      'react',
      'node',
      'express',
      'aws',
      'firebase',
      'sql',
      'nosql',
      'mongodb',
      'docker',
      'kubernetes',
      'git',
      'github',
      'jira',
      'figma',
      'adobe',
      'c++',
      'c#',
      'swift',
      'kotlin',
      'android',
      'ios',
      'html',
      'css',
      'machine learning',
      'ai',
      'data analysis',
      'excel',
      'communication',
      'leadership',
      'agile',
      'scrum',
      'problem solving'
    ];

    final lowerText = text.toLowerCase();
    final Set<String> foundSkills = {};

    for (final skill in commonSkills) {
      // Check for exact word matches or boundary matches
      if (lowerText.contains(skill.toLowerCase())) {
        // rudimentary matching
        foundSkills.add(skill[0].toUpperCase() + skill.substring(1));
      }
    }
    return foundSkills.toList();
  }

  String _determineCategory(String text, List<String> skills) {
    final lowerText = text.toLowerCase();

    if (skills.any((s) => [
          'flutter',
          'android',
          'ios',
          'swift',
          'kotlin',
          'react native'
        ].contains(s.toLowerCase()))) {
      return 'Mobile Developer';
    }
    if (skills.any((s) => [
          'react',
          'vue',
          'angular',
          'html',
          'css',
          'javascript'
        ].contains(s.toLowerCase()))) {
      return 'Frontend Developer';
    }
    if (skills.any((s) =>
        ['node', 'python', 'java', 'sql', 'aws'].contains(s.toLowerCase()))) {
      return 'Backend Developer';
    }
    if (lowerText.contains('designer') ||
        lowerText.contains('ui/ux') ||
        skills.contains('Figma')) {
      return 'Designer';
    }
    return 'General';
  }

  // The "Smart Summarizer" algorithm provided by the user
  String _summarizeText(String text, {int maxSentences = 5}) {
    if (text.isEmpty)
      return 'Motivated professional looking for new opportunities.';

    final sentences =
        text.replaceAll('\n', ' ').split(RegExp(r'(?<=[.!?])\s+'));

    if (sentences.length <= maxSentences) {
      return sentences.join(' ');
    }

    // Keyword frequency
    final Map<String, int> freq = {};
    for (final word in text.toLowerCase().split(RegExp(r'\W+'))) {
      if (word.length > 4) {
        freq[word] = (freq[word] ?? 0) + 1;
      }
    }

    // Score sentences
    final scored = sentences.map((s) {
      int score = 0;
      for (final word in s.toLowerCase().split(RegExp(r'\W+'))) {
        score += freq[word] ?? 0;
      }
      return MapEntry(s, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    var summary = scored.take(maxSentences).map((e) => e.key.trim()).join(' ');

    if (summary.length > 300) {
      summary = summary.substring(0, 300) + '...';
    }

    return summary;
  }

  List<WorkExperience> _extractWorkExperience(String text) {
    // Heuristic: Look for blocks starting with typical experience headers
    // This is very rudimentary without NLP entity recognition.
    // We will try to find lines that look like "Role at Company" or date ranges.

    final List<WorkExperience> experiences = [];
    final lowerText = text.toLowerCase();

    // 1. Identify section start
    final sectionKeywords = [
      'experience',
      'work history',
      'employment',
      'career history'
    ];
    int startIndex = -1;

    for (var keyword in sectionKeywords) {
      final idx = lowerText.indexOf(keyword);
      if (idx != -1) {
        startIndex = idx;
        break;
      }
    }

    if (startIndex == -1) return []; // No section found

    // 2. Extract lines after section start until next section
    final subText = text.substring(startIndex);
    final lines = subText.split('\n');

    // Skip header lines
    int i = 1;

    // Try to extract at least one or two distinct roles
    // Pattern: Title at Company | Date - Date

    String? currentTitle;
    String? currentCompany;

    // Simple iteration just to grab *some* data for display
    for (; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Stop if we hit another main section
      if (['education', 'skills', 'projects', 'languages']
          .any((s) => line.toLowerCase().contains(s))) break;

      if (currentTitle == null) {
        // Assume first significant line is title
        if (line.length > 5 && line.length < 50) {
          currentTitle = line;
          continue;
        }
      } else if (currentCompany == null) {
        // Assume next is company/date
        currentCompany = line;
        experiences.add(WorkExperience(
            title: currentTitle,
            company: currentCompany,
            duration: "See Resume", // Date parsing is hard locally
            description: "Extracted from resume."));
        // Reset to find next
        currentTitle = null;
        currentCompany = null;
      }

      if (experiences.length >= 3) break;
    }

    return experiences;
  }

  List<Education> _extractEducation(String text) {
    final List<Education> educations = [];
    final lowerText = text.toLowerCase();

    final sectionKeywords = ['education', 'academic', 'qualification'];
    int startIndex = -1;

    for (var keyword in sectionKeywords) {
      final idx = lowerText.indexOf(keyword);
      if (idx != -1) {
        startIndex = idx;
        break;
      }
    }

    if (startIndex == -1) return [];

    final subText = text.substring(startIndex);
    final lines = subText.split('\n');

    int i = 1;
    String? degree;
    String? school;

    for (; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (['skills', 'experience', 'projects', 'languages']
          .any((s) => line.toLowerCase().contains(s))) break;

      if (degree == null) {
        if (line.length > 5 && line.length < 60) {
          degree = line;
          continue;
        }
      } else if (school == null) {
        school = line;
        educations
            .add(Education(degree: degree, institution: school, year: "Year"));
        degree = null;
        school = null;
      }
      if (educations.length >= 2) break;
    }
    return educations;
  }

  List<Project> _extractProjects(String text) {
    // Similar heuristic logic
    return [];
  }
}

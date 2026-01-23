import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/resume_data_model.dart';
import 'gemini_service.dart';
import 'ocr_service.dart';

class ResumeParserService {
  final _geminiService = GeminiService();

  Future<ResumeData?> parseResume(File file) async {
    final ext = file.path.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
      debugPrint('Processing as Image (OCR -> HF)...');

      // Use OCR first to get text from the image
      final ocrText = await OcrService.extractText(file);

      if (ocrText.trim().isNotEmpty) {
        return await _geminiService.parseResume(ocrText);
      } else {
        throw Exception("OCR failed to extract text from image.");
      }
    } else if (ext == 'pdf') {
      debugPrint('Processing as PDF...');
      // Try text extraction first (faster, cheaper, better for digital PDFs)
      final text = await _extractPdfText(file);

      if (text.trim().length > 50) {
        debugPrint('Extracted Text length: ${text.length}');
        return await _geminiService.parseResume(text);
      } else {
        debugPrint('PDF text empty or too short, falling back to OCR...');
        // Fallback to OCR for scanned PDFs
        // OcrService supports PDF uploads to OCR.space
        final ocrText = await OcrService.extractText(file);
        if (ocrText.isNotEmpty) {
          return await _geminiService.parseResume(ocrText);
        }
      }
    } else {
      // Doc, Docx, etc. - Try OCR.space
      debugPrint('Processing as $ext using OCR...');
      final ocrText = await OcrService.extractText(file);
      if (ocrText.isNotEmpty) {
        return await _geminiService.parseResume(ocrText);
      }
    }
    return null;
  }

  Future<String> _extractPdfText(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('PDF Extraction Error: $e');
      return '';
    }
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:work_hub/core/config/app_export.dart';
import '../logic/resume_parse_provider.dart';
import 'resume_preview_screen.dart';

class ResumeUploadScreen extends StatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  Future<void> _pickAndParse(BuildContext context) async {
    final provider = context.read<ResumeParseProvider>();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;

      // 1. Show extraction state
      provider.setExtractingStatus();

      try {
        // 2. Extract Text
        debugPrint('Extracting text from: $path');
        final PdfDocument document =
            PdfDocument(inputBytes: File(path).readAsBytesSync());
        String text = PdfTextExtractor(document).extractText();
        document.dispose();
        debugPrint('Extracted ${text.length} characters');

        if (text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not extract text from this PDF.')),
          );
          return;
        }

        // 3. Submit for AI Parsing
        await provider.submitResume(text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeParseProvider>();

    // If parsing completes successfully, navigate to preview
    if (provider.status == ResumeParseStatus.done &&
        provider.parsedData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResumePreviewScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// HEADER WITH BACK BUTTON
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'AI Resume Parser',
                    style: TextStyleHelper.instance.headline22Bold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            /// WHITE BODY
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: appTheme.white_A700_01,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.all(24.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 40.h),
                          FadeInDown(
                            child: Icon(
                              Icons.description_outlined,
                              size: 80.h,
                              color: CustomColors.primaryBlue,
                            ),
                          ),
                          SizedBox(height: 32.h),
                          FadeInUp(
                            child: Text(
                              'Improve Your Profile with AI',
                              style: TextStyleHelper.instance.headline22Bold.copyWith(
                                color: appTheme.gray_900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: Text(
                              'Upload your resume (PDF) and let our AI extract your skills, experience, and score your profile.',
                              style: TextStyleHelper.instance.body16Regular.copyWith(
                                color: appTheme.gray_500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 48.h),
                          if (provider.status == ResumeParseStatus.idle ||
                              provider.status == ResumeParseStatus.error) ...[
                            if (provider.error != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 24.h),
                                child: Container(
                                  padding: EdgeInsets.all(12.h),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.h),
                                  ),
                                  child: Text(
                                    provider.error!,
                                    style: TextStyleHelper.instance.body12Medium.copyWith(
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _pickAndParse(context),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Resume (PDF)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CustomColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.h)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (provider.status != ResumeParseStatus.idle &&
                        provider.status != ResumeParseStatus.error &&
                        provider.status != ResumeParseStatus.done)
                      _buildLoadingOverlay(provider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(ResumeParseProvider provider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.h),
          topRight: Radius.circular(32.h),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeIn(
              animate: true,
              duration: const Duration(seconds: 2),
              child: Container(
                width: 120.h,
                height: 120.h,
                decoration: BoxDecoration(
                  color: CustomColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 60.h,
                  color: CustomColors.primaryBlue,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            SlideInUp(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _getStatusText(provider.status),
                style: TextStyleHelper.instance.headline22Bold.copyWith(
                  color: CustomColors.primaryBlue,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            FadeIn(
              delay: const Duration(milliseconds: 400),
              child: Text(
                'AI is weaving your professional story...',
                style: TextStyleHelper.instance.body14Medium.copyWith(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 48.h),
            SizedBox(
              width: 200.w,
              child: LinearProgressIndicator(
                backgroundColor: CustomColors.lightBlue,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(CustomColors.primaryBlue),
                minHeight: 6.h,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(ResumeParseStatus status) {
    switch (status) {
      case ResumeParseStatus.extractingText:
        return 'Extracting Wisdom...';
      case ResumeParseStatus.uploading:
        return 'Uploading to Brain...';
      case ResumeParseStatus.processing:
        return 'AI is Analyzing...';
      default:
        return 'Processing...';
    }
  }
}
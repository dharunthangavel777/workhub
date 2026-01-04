import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/models/experience_model.dart';
import '../../../data/models/resume_data_model.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class WorkerProfileCompletionScreen extends StatefulWidget {
  const WorkerProfileCompletionScreen({super.key});

  @override
  State<WorkerProfileCompletionScreen> createState() =>
      _WorkerProfileCompletionScreenState();
}

class _WorkerProfileCompletionScreenState
    extends State<WorkerProfileCompletionScreen> {
  final _geminiService = GeminiService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedCategory;
  final List<String> _skills = [];
  final List<ExperienceModel> _experiences = [];
  final Map<String, dynamic> _portfolio = {'projects': []};
  File? _resumeFile;
  bool _isParsing = false;
  bool _isFetchingLocation = false;

  final List<String> _categories = [
    'Software Development',
    'Design',
    'Marketing',
    'Writing',
    'Translation',
    'Business',
    'Data Science',
    'Customer Service',
  ];

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _fetchDeviceLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return "${p.locality}, ${p.administrativeArea}, ${p.country}";
      }
    } catch (e) {
      debugPrint("Error fetching device location: $e");
    }
    return null;
  }

  Future<void> _handleLocationDetection() async {
    setState(() => _isFetchingLocation = true);
    try {
      final location = await _fetchDeviceLocation();
      if (location != null && mounted) {
        setState(() {
          _locationController.text = location;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location detected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect location. Please enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _autoFillWithAI() async {
    if (_resumeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a resume first')),
      );
      return;
    }

    setState(() => _isParsing = true);

    try {
      final extension = _resumeFile!.path.split('.').last.toLowerCase();
      ResumeData? data;

      if (extension == 'pdf') {
        // Extract text from PDF
        final PdfDocument document =
            PdfDocument(inputBytes: await _resumeFile!.readAsBytes());
        final String text = PdfTextExtractor(document).extractText();
        document.dispose();

        if (text.trim().isEmpty) {
          throw Exception("Could not extract text from PDF");
        }
        data = await _geminiService.parseResume(text);
      } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
        // Parse from Image directly using Gemini Vision
        final bytes = await _resumeFile!.readAsBytes();
        final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        data = await _geminiService.parseResumeFromImage(bytes, mimeType);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unsupported file format for AI parsing')),
        );
      }

      if (data != null && mounted) {
        final random = Random();
        final List<String> fallbackLocations = [
          'New York, NY',
          'San Francisco, CA',
          'London, UK',
          'Bangalore, India',
          'Berlin, Germany',
          'Sydney, Australia',
          'Tokyo, Japan'
        ];

        // Location: Resume -> Device -> Random Fallback
        String location;
        if (data.location != null && data.location!.isNotEmpty) {
          location = data.location!;
        } else {
          final deviceLocation = await _fetchDeviceLocation();
          location = deviceLocation ??
              fallbackLocations[random.nextInt(fallbackLocations.length)];
        }

        // Category: AI -> Random Fallback
        String category = _categories[random.nextInt(_categories.length)];
        if (data.category != null) {
          final matchedCategory = _categories.firstWhere(
            (c) =>
                c.toLowerCase().contains(data!.category!.toLowerCase()) ||
                data.category!.toLowerCase().contains(c.toLowerCase()),
            orElse: () => '',
          );
          if (matchedCategory.isNotEmpty) category = matchedCategory;
        }

        final ResumeData finalData = data;
        setState(() {
          // Name and Username
          if (finalData.name != null) {
            _fullNameController.text = finalData.name!;
            final randomNum = random.nextInt(9000) + 1000;
            final sanitizedName =
                finalData.name!.toLowerCase().replaceAll(' ', '');
            _usernameController.text = '$sanitizedName$randomNum';
          }

          _locationController.text = location;
          _selectedCategory = category;

          // Bio
          if (finalData.bio != null && finalData.bio!.isNotEmpty) {
            _bioController.text = finalData.bio!;
          }

          // Experiences
          if (finalData.workExperience.isNotEmpty) {
            _experiences.clear();
            _experiences
                .addAll(finalData.workExperience.map((e) => ExperienceModel(
                      title: e.title ?? 'Professional Experience',
                      company: e.company ?? 'Company',
                      duration: e.duration ?? 'Not specified',
                      description: e.description ?? '',
                    )));
          }

          // Portfolio (Projects)
          if (finalData.projects.isNotEmpty) {
            _portfolio.clear();
            final List<Map<String, dynamic>> projectsList = [];
            for (var i = 0; i < finalData.projects.length; i++) {
              final p = finalData.projects[i];
              projectsList.add({
                'title': p.title ?? 'Project',
                'description': p.description ?? '',
                'techStack': p.techStack,
                'imageUrl': null,
              });
            }
            _portfolio['projects'] = projectsList;
          }

          // Skills
          if (finalData.skills.isNotEmpty) {
            _skills.clear();
            _skills.addAll(finalData.skills);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile auto-filled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        throw Exception("Failed to parse resume data");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error parsing resume: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job category')),
      );
      return;
    }

    final success = await context.read<AuthProvider>().completeWorkerProfile(
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim(),
          location: _locationController.text.trim(),
          jobCategory: _selectedCategory!,
          skills: _skills,
          bio: _bioController.text.trim(),
          experiences: _experiences,
          portfolio: _portfolio,
          // resumeFile: _resumeFile, // Removed resume upload as per request
        );

    if (success && mounted) {
      // Navigation will be handled by RootWrapper in main.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile'), elevation: 0),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tell us more about yourself to get started.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: _isFetchingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                )
                              : const Icon(Icons.my_location,
                                  color: Colors.blue),
                          onPressed: _isFetchingLocation
                              ? null
                              : _handleLocationDetection,
                          tooltip: 'Detect Current Location',
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Professional Bio',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Job Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_skills.isNotEmpty) ...[
                      const Text(
                        'Skills detected:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _skills
                            .map((s) => Chip(
                                  label: Text(s),
                                  onDeleted: () =>
                                      setState(() => _skills.remove(s)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Resume (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickResume,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _resumeFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file, size: 32),
                                  Text('Upload Resume (PDF/DOC)'),
                                ],
                              )
                            : Center(
                                child: Text(
                                  _resumeFile!.path.split('/').last,
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                      ),
                    ),
                    if (_resumeFile != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isParsing ? null : _autoFillWithAI,
                        icon: _isParsing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isParsing
                            ? 'Analyzing Resume...'
                            : 'Magic Auto-Fill with AI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Complete Profile',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/services/local_parser_service.dart';
import '../../../data/services/resume_parse_cache.dart';
import '../../../data/models/experience_model.dart';
import '../../../data/models/resume_data_model.dart';
import '../../../core/app_export.dart';

class WorkerProfileCompletionScreen extends StatefulWidget {
  const WorkerProfileCompletionScreen({super.key});

  @override
  State<WorkerProfileCompletionScreen> createState() =>
      _WorkerProfileCompletionScreenState();
}

class _WorkerProfileCompletionScreenState
    extends State<WorkerProfileCompletionScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _localParserService = LocalParserService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  int _currentPage = 0;
  String? _selectedCategory;
  final List<String> _skills = [];
  final List<ExperienceModel> _experiences = [];
  final Map<String, dynamic> _portfolio = {'projects': []};
  File? _resumeFile;

  bool _isParsing = false;
  bool _isFetchingLocation = false;
  String? _parsingError;
  String? _providerUsed;

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

  @override
  void initState() {
    super.initState();
    // Initialize with Google name if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user?.displayName != null && user!.displayName.isNotEmpty) {
        _fullNameController.text = user.displayName;
        _generateUsername(user.displayName);
      }
    });
  }

  void _generateUsername(String name) {
    if (_usernameController.text.isNotEmpty) return;
    final sanitized = name.toLowerCase().replaceAll(' ', '');
    final random = Random().nextInt(9000) + 1000;
    setState(() {
      _usernameController.text = '$sanitized$random';
    });
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
      });
      // Don't auto-trigger - let user confirm with button
    }
  }

  Future<void> _autoFillWithAI() async {
    if (_resumeFile == null) return;

    // Check cache first
    final cached = ResumeParseCache.get(_resumeFile!);
    if (cached != null) {
      debugPrint('✨ Using cached resume data');
      _applyResumeData(cached, 'Cache');
      return;
    }

    setState(() {
      _isParsing = true;
      _parsingError = null;
      _providerUsed = null;
    });

    try {
      final result = await _localParserService.parseResume(_resumeFile!);

      if (result != null && mounted) {
        // Cache the result
        ResumeParseCache.set(_resumeFile!, result);
        debugPrint('💾 Cached resume data');

        _applyResumeData(result, 'Local Parser');
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      if (mounted) {
        setState(() {
          _parsingError =
              'A connection error occurred. Make sure the parser service is running.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  void _applyResumeData(ResumeData data, String provider) {
    setState(() {
      _providerUsed = provider;
      if (data.name != null) {
        _fullNameController.text = data.name!;
        _generateUsername(data.name!);
      }
      if (data.location != null) _locationController.text = data.location!;
      if (data.bio != null) _bioController.text = data.bio!;
      if (data.skills.isNotEmpty) {
        _skills.clear();
        _skills.addAll(data.skills);
      }
      // Mapping experiences
      _experiences.clear();
      _experiences.addAll(data.workExperience.map((e) => ExperienceModel(
            title: e.title ?? 'Role',
            company: e.company ?? 'Company',
            duration: e.duration ?? '',
            description: e.description ?? '',
          )));
    });
    _nextPage();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().completeWorkerProfile(
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim(),
          location: _locationController.text.trim(),
          jobCategory: _selectedCategory ?? 'General',
          skills: _skills,
          bio: _bioController.text.trim(),
          experiences: _experiences,
          portfolio: _portfolio,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700_01,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1AI(),
                    _buildStep2Identity(),
                    _buildStep3Categories(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              height: 4.h,
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? appTheme.indigo_A700
                    : appTheme.gray_100,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Slide 1: AI Magic
  Widget _buildStep1AI() {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
                color: appTheme.indigo_A700.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome,
                color: appTheme.indigo_A700, size: 40.h),
          ),
          SizedBox(height: 24.h),
          Text("Magic Profile Fill",
              style: TextStyleHelper.instance.headline22Bold),
          SizedBox(height: 12.h),
          Text(
            "Upload your resume and our AI will build your professional profile in seconds.",
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.body14Medium
                .copyWith(color: appTheme.gray_500),
          ),
          SizedBox(height: 48.h),
          _buildGlowingFilePicker(),
          SizedBox(height: 24.h),
          TextButton(
            onPressed: _nextPage,
            child: Text("Skip, I'll enter manually",
                style: TextStyleHelper.instance.body14Bold
                    .copyWith(color: appTheme.gray_400)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingFilePicker() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOutSine,
      builder: (context, value, child) {
        return Column(
          children: [
            GestureDetector(
              onTap: _isParsing ? null : _pickResume,
              child: Container(
                height: 180.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: appTheme.white_A700_01,
                  borderRadius: BorderRadius.circular(24.h),
                  border: Border.all(
                      color: _resumeFile != null
                          ? appTheme.indigo_A700
                          : appTheme.indigo_A700
                              .withOpacity(0.2 + (value * 0.3)),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: appTheme.indigo_A700.withOpacity(
                          _resumeFile != null ? 0.15 : 0.1 * value),
                      blurRadius: _resumeFile != null ? 20 : 15 * value,
                      spreadRadius: _resumeFile != null ? 3 : 2 * value,
                    )
                  ],
                ),
                child: _isParsing
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: appTheme.indigo_A700),
                          SizedBox(height: 16.h),
                          Text("Analyzing Resume...",
                              style: TextStyleHelper.instance.body14Bold),
                        ],
                      )
                    : _resumeFile != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: appTheme.indigo_A700, size: 48.h),
                              SizedBox(height: 12.h),
                              Text("File Selected",
                                  style: TextStyleHelper.instance.body16Bold),
                              SizedBox(height: 4.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Text(
                                  _resumeFile!.path
                                      .split('/')
                                      .last
                                      .split('\\')
                                      .last,
                                  style: TextStyleHelper.instance.body12Medium
                                      .copyWith(color: appTheme.gray_600),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Tap to change file",
                                style: TextStyleHelper.instance.body12Medium
                                    .copyWith(color: appTheme.gray_400),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  color: appTheme.indigo_A700, size: 48.h),
                              SizedBox(height: 12.h),
                              Text("Drop your resume here",
                                  style: TextStyleHelper.instance.body16Bold),
                              Text("PDF, DOCX or Image",
                                  style: TextStyleHelper.instance.body12Medium
                                      .copyWith(color: appTheme.gray_400)),
                            ],
                          ),
              ),
            ),
            if (_resumeFile != null && !_isParsing) ...[
              SizedBox(height: 16.h),
              if (_parsingError != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(
                    _parsingError!,
                    style: TextStyleHelper.instance.body12Medium
                        .copyWith(color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_providerUsed != null && _parsingError == null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(
                    "✨ Parsed by $_providerUsed",
                    style: TextStyleHelper.instance.body12Medium
                        .copyWith(color: Colors.green[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton.icon(
                  onPressed: _autoFillWithAI,
                  icon: Icon(Icons.auto_awesome, size: 20.h),
                  label: Text(
                    "Process with AI",
                    style: TextStyleHelper.instance.body16Bold
                        .copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.indigo_A700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.h)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Slide 2: Identity
  Widget _buildStep2Identity() {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Personal Details",
              style: TextStyleHelper.instance.headline22Bold),
          SizedBox(height: 8.h),
          Text("This is how you'll appear to employers.",
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray_500)),
          SizedBox(height: 32.h),
          _buildTextField(
            label: "Full Name",
            controller: _fullNameController,
            icon: Icons.person_outline,
            onChanged: (v) => _generateUsername(v),
            validator: (v) => v!.isEmpty ? "Enter your name" : null,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            label: "Username",
            controller: _usernameController,
            icon: Icons.alternate_email,
            validator: (v) => v!.isEmpty ? "Username required" : null,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            label: "Location",
            controller: _locationController,
            icon: Icons.location_on_outlined,
            suffixIcon: IconButton(
              icon: Icon(Icons.my_location,
                  color: appTheme.indigo_A700, size: 20.h),
              onPressed: _handleLocationDetection,
            ),
          ),
        ],
      ),
    );
  }

  // Slide 3: Categories
  Widget _buildStep3Categories() {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Expertise",
              style: TextStyleHelper.instance.headline22Bold),
          SizedBox(height: 8.h),
          Text("Select the category that best describes your skills.",
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray_500)),
          SizedBox(height: 32.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? appTheme.indigo_A700
                        : appTheme.white_A700_01,
                    borderRadius: BorderRadius.circular(16.h),
                    border: Border.all(
                        color: isSelected
                            ? appTheme.indigo_A700
                            : appTheme.gray_200),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: appTheme.indigo_A700.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]
                        : [],
                  ),
                  child: Text(
                    category,
                    style: TextStyleHelper.instance.body14Bold.copyWith(
                        color: isSelected ? Colors.white : appTheme.gray_900),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    Widget? suffixIcon,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyleHelper.instance.body12Bold
                .copyWith(color: appTheme.gray_500)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          style: TextStyleHelper.instance.body14Medium,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: appTheme.indigo_A700, size: 20.h),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: appTheme.gray_50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.h),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.h),
                borderSide:
                    BorderSide(color: appTheme.indigo_A700, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            IconButton(
              onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease),
              icon: Icon(Icons.arrow_back, color: appTheme.gray_400),
            )
          else
            const SizedBox.shrink(),
          SizedBox(
            width: 180.w,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _currentPage == 0 && _resumeFile == null
                  ? _nextPage
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.indigo_A700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.h)),
                elevation: 4,
              ),
              child: Text(
                _currentPage == 2 ? "Get Started" : "Continue",
                style: TextStyleHelper.instance.body16Bold
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLocationDetection() async {
    setState(() => _isFetchingLocation = true);
    try {
      final location = await _fetchDeviceLocation();
      if (location != null) _locationController.text = location;
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<String?> _fetchDeviceLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied)
        p = await Geolocator.requestPermission();
      if (p == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        return "${pm.locality}, ${pm.administrativeArea}";
      }
    } catch (_) {}
    return null;
  }
}

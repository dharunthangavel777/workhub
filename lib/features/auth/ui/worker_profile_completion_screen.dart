import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:animate_do/animate_do.dart';
import 'package:qwok/core/config/app_export.dart';
import 'package:qwok/features/profile/domain/models/experience.dart';
import 'package:qwok/features/auth/logic/auth_controller.dart';

import 'package:qwok/features/ai/logic/resume_parse_provider.dart';
import 'package:qwok/features/ai/domain/models/resume_data_model.dart';

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
  final List<Map<String, dynamic>> _certifications = [];
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

      // Listen for AI parsing results
      context.read<ResumeParseProvider>().addListener(_onAiParseUpdate);
    });
  }

  @override
  void dispose() {
    // Remove listener properly
    context.read<ResumeParseProvider>().removeListener(_onAiParseUpdate);
    super.dispose();
  }

  void _onAiParseUpdate() {
    if (!mounted) return;
    final provider = context.read<ResumeParseProvider>();

    if (provider.status == ResumeParseStatus.done &&
        provider.parsedData != null) {
      _applyResumeData(provider.parsedData!, 'AI Engine');
      setState(() {
        _isParsing = false;
      });
      // Move to review page automatically
      _nextPage();

      // Reset provider so we don't apply again on next build/update
      provider.reset();
    } else if (provider.status == ResumeParseStatus.error) {
      setState(() {
        _parsingError = provider.error;
        _isParsing = false;
      });
    }
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
      // Automatic trigger - process immediately after picking
      _autoFillWithAI();
    }
  }

  Future<void> _autoFillWithAI() async {
    if (_resumeFile == null) return;

    setState(() {
      _isParsing = true;
      _parsingError = null;
    });

    try {
      final provider = context.read<ResumeParseProvider>();
      // 1. Extract Text locally
      provider.setExtractingStatus();
      debugPrint(
          'WorkerProfileCompletion: Extracting text from ${_resumeFile!.path}');

      final PdfDocument document =
          PdfDocument(inputBytes: _resumeFile!.readAsBytesSync());
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      debugPrint(
          'WorkerProfileCompletion: Extracted ${text.length} characters');

      if (text.trim().isEmpty) {
        throw Exception("Could not extract text from this PDF.");
      }

      // 2. Submit to our Backend AI Provider
      debugPrint('WorkerProfileCompletion: Submitting for AI Parsing...');
      await provider.submitResume(text);
    } catch (e) {
      debugPrint('AI Completion Error: $e');
      if (mounted) {
        setState(() {
          _parsingError = 'AI Error: $e';
          _isParsing = false;
        });
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
        _skills.addAll(data.skills.allSkills.map((s) => s.name));
      }
      // Mapping experiences
      _experiences.clear();
      _experiences.addAll(data.workExperience
          .map((e) => ExperienceModel(
                title: e.title ?? 'Role',
                company: e.company ?? 'Company',
                duration: e.duration ?? '',
                description: e.description ?? '',
              ))
          .toList());

      // Mapping projects
      _portfolio.clear();
      for (var p in data.projects) {
        final id = DateTime.now().millisecondsSinceEpoch.toString() +
            p.title.hashCode.toString();
        _portfolio[id] = {
          'title': p.title,
          'description': p.description,
          'image': '',
        };
      }

      // Mapping certifications
      _certifications.clear();
      _certifications.addAll(data.certifications.map((c) => c.toJson()));
    });
    // Removed _nextPage() to let user see summary
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
          certifications: _certifications,
          resumeFile: _resumeFile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<ResumeParseProvider>();
    final isStatingAi = aiProvider.status != ResumeParseStatus.idle &&
        aiProvider.status != ResumeParseStatus.error &&
        aiProvider.status != ResumeParseStatus.done;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
            if (isStatingAi || _isParsing) _buildAILoadingOverlay(aiProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAILoadingOverlay(ResumeParseProvider provider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white.withValues(alpha: 0.7),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeIn(
              animate: true,
              duration: const Duration(seconds: 2),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: appTheme.indigoA700.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: appTheme.indigoA700.withValues(alpha: 0.2),
                      width: 2),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 60.h,
                  color: appTheme.indigoA700,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              _getAIStatusText(provider.status),
              style: TextStyleHelper.instance.headline22Bold
                  .copyWith(color: appTheme.indigoA700),
            ),
            SizedBox(height: 12.h),
            const Text(
              "AI is analyzing your professional journey...",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: 200.w,
              child: LinearProgressIndicator(
                backgroundColor: appTheme.indigoA700.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(appTheme.indigoA700),
                minHeight: 6,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Please wait, this might take a moment.",
              style: TextStyleHelper.instance.body12Medium
                  .copyWith(color: appTheme.gray400),
            ),
          ],
        ),
      ),
    );
  }

  String _getAIStatusText(ResumeParseStatus status) {
    switch (status) {
      case ResumeParseStatus.extractingText:
        return "Reading Resume...";
      case ResumeParseStatus.uploading:
        return "Thinking Big...";
      case ResumeParseStatus.processing:
        return "AI Analysis...";
      default:
        return "Processing...";
    }
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
                    ? appTheme.indigoA700
                    : appTheme.gray100,
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
                color: appTheme.indigoA700.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome,
                color: appTheme.indigoA700, size: 40.h),
          ),
          SizedBox(height: 24.h),
          Text("Magic Profile Fill",
              style: TextStyleHelper.instance.headline22Bold),
          SizedBox(height: 12.h),
          Text(
            "Upload your resume and our AI will build your professional profile in seconds.",
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.body14Medium
                .copyWith(color: appTheme.gray500),
          ),
          SizedBox(height: 48.h),
          _buildGlowingFilePicker(),
          SizedBox(height: 24.h),
          TextButton(
            onPressed: _nextPage,
            child: Text("Skip, I'll enter manually",
                style: TextStyleHelper.instance.body14Bold
                    .copyWith(color: appTheme.gray400)),
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
                  color: appTheme.whiteA70001,
                  borderRadius: BorderRadius.circular(24.h),
                  border: Border.all(
                      color: _resumeFile != null
                          ? appTheme.indigoA700
                          : appTheme.indigoA700
                              .withValues(alpha: 0.2 + (value * 0.3)),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: appTheme.indigoA700.withValues(
                          alpha: _resumeFile != null ? 0.15 : 0.1 * value),
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
                              color: appTheme.indigoA700),
                          SizedBox(height: 16.h),
                          Text(
                            context.watch<ResumeParseProvider>().status ==
                                    ResumeParseStatus.processing
                                ? "AI is analyzing..."
                                : "Uploading...",
                            style: TextStyleHelper.instance.body14Bold,
                          ),
                        ],
                      )
                    : _resumeFile != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: appTheme.indigoA700, size: 48.h),
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
                                      .copyWith(color: appTheme.gray600),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Tap to change file",
                                style: TextStyleHelper.instance.body12Medium
                                    .copyWith(color: appTheme.gray400),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  color: appTheme.indigoA700, size: 48.h),
                              SizedBox(height: 12.h),
                              Text("Drop your resume here",
                                  style: TextStyleHelper.instance.body16Bold),
                              Text("PDF, DOCX or Image",
                                  style: TextStyleHelper.instance.body12Medium
                                      .copyWith(color: appTheme.gray400)),
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
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  children: [
                    Text(
                      "✨ Parsed by $_providerUsed",
                      style: TextStyleHelper.instance.body12Medium
                          .copyWith(color: Colors.green[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Found: ${_experiences.length} Exp, ${_portfolio['projects']?.length ?? 0} Proj, ${_certifications.length} Certs",
                      style: TextStyleHelper.instance.body12Bold
                          .copyWith(color: appTheme.indigoA700),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Profile auto-filled! Click next to review.",
                      style: TextStyleHelper.instance.body12Medium
                          .copyWith(color: appTheme.gray600),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
                    backgroundColor: appTheme.indigoA700,
                    foregroundColor: Colors.white,
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
                  .copyWith(color: appTheme.gray500)),
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
            suffixIcon: _isFetchingLocation
                ? Padding(
                    padding: EdgeInsets.all(12.h),
                    child: SizedBox(
                      width: 20.h,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: appTheme.indigoA700,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.my_location,
                        color: appTheme.indigoA700, size: 20.h),
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
                  .copyWith(color: appTheme.gray500)),
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
                        ? appTheme.indigoA700
                        : appTheme.whiteA70001,
                    borderRadius: BorderRadius.circular(16.h),
                    border: Border.all(
                        color: isSelected
                            ? appTheme.indigoA700
                            : appTheme.gray200),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color:
                                    appTheme.indigoA700.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]
                        : [],
                  ),
                  child: Text(
                    category,
                    style: TextStyleHelper.instance.body14Bold.copyWith(
                        color: isSelected ? Colors.white : appTheme.gray900),
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
                .copyWith(color: appTheme.gray500)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          style: TextStyleHelper.instance.body14Medium,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: appTheme.indigoA700, size: 20.h),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: appTheme.gray50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.h),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.h),
                borderSide:
                    BorderSide(color: appTheme.indigoA700, width: 1.5)),
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
              icon: Icon(Icons.arrow_back, color: appTheme.gray400),
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
                backgroundColor: appTheme.indigoA700,
                foregroundColor: Colors.white,
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
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
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




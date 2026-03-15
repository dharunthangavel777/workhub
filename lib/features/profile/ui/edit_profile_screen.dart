import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qwok/core/config/app_export.dart';
import 'package:qwok/core/utils/image_utils.dart';
import 'package:qwok/features/auth/logic/auth_controller.dart';
import 'package:qwok/features/profile/domain/models/experience.dart';
import 'package:qwok/features/ai/services/local_parser_service.dart';
import 'package:qwok/features/ai/domain/models/resume_data_model.dart' as ai;
import 'package:file_picker/file_picker.dart';
import 'package:qwok/core/services/toast_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _jobCategoryController;
  late TextEditingController _skillsController;
  final _resumeParserService = ResumeParserService();
  bool _isParsing = false;
  List<ExperienceModel>? _parsedExperiences;
  List<ai.Project>? _parsedProjects;
  List<ai.Certification>? _parsedCertifications;
  String? _resumeUrl;
  File? _newResumeFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    _nameController = TextEditingController(text: user?.displayName);
    _usernameController = TextEditingController(text: user?.username);
    _bioController = TextEditingController(text: user?.bio);
    _locationController = TextEditingController(text: user?.location);
    _jobCategoryController = TextEditingController(text: user?.jobCategory);
    _skillsController = TextEditingController(text: user?.skills?.map((s) => s.name).join(', '));
    _resumeUrl = user?.resumeUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _jobCategoryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _magicFill() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isParsing = true);
      try {
        final resumeFile = File(result.files.single.path!);
        _newResumeFile = resumeFile;
        final data = await _resumeParserService.parseResume(resumeFile);

        if (data != null && mounted) {
          setState(() {
            _resumeUrl = data.rawData?['resumeUrl']; // Keep track if provided
            if (data.name != null && data.name!.isNotEmpty) {
              _nameController.text = data.name!;
            }
            if (data.bio != null && data.bio!.isNotEmpty) {
              _bioController.text = data.bio!;
            }
            if (data.location != null && data.location!.isNotEmpty) {
              _locationController.text = data.location!;
            }
            if (data.category != null && data.category!.isNotEmpty) {
              _jobCategoryController.text = data.category!;
            }
            if (data.skills.isNotEmpty) {
              _skillsController.text = data.skills.allSkills.map((s) => s.name).join(', ');
            }
            if (data.workExperience.isNotEmpty) {
              _parsedExperiences = data.workExperience
                  .map((e) => ExperienceModel(
                        title: e.title ?? 'Role',
                        company: e.company ?? 'Company',
                        duration: e.duration ?? 'Duration',
                        description: e.description ?? '',
                      ))
                  .toList();
            }
            if (data.projects.isNotEmpty) {
              _parsedProjects = data.projects;
            }
            if (data.certifications.isNotEmpty) {
              _parsedCertifications = data.certifications;
            }
          });
          ToastService().showSuccess('Magic Fill', message: "✨ Profile auto-filled! ${data.workExperience.length} exp, ${data.projects.length} projects, ${data.certifications.length} certs found.");
        }
      } catch (e) {
        debugPrint("Magic Fill Error: $e");
        if (mounted) {
          ToastService().showError('Parsing Error', message: "Failed to parse resume: $e");
        }
      } finally {
        if (mounted) setState(() => _isParsing = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();

      final updates = <String, dynamic>{
        'displayName': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'jobCategory': _jobCategoryController.text.trim(),
        'skills': _skillsController.text.trim().isNotEmpty
            ? _skillsController.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
            : [],
      };

      if (_parsedExperiences != null) {
        updates['experiences'] =
            _parsedExperiences!.map((e) => e.toMap()).toList();
      }
      if (_parsedProjects != null) {
        Map<String, dynamic> portfolio =
            Map<String, dynamic>.from(auth.userModel?.portfolio ?? {});
        for (var p in _parsedProjects!) {
          final id = DateTime.now().millisecondsSinceEpoch.toString() +
              p.title.hashCode.toString();
          portfolio[id] = {
            'title': p.title,
            'description': p.description,
            'image': '',
          };
        }
        updates['portfolio'] = portfolio;
      }
      if (_parsedCertifications != null) {
        updates['certifications'] =
            _parsedCertifications!.map((c) => c.toJson()).toList();
      }
      if (_resumeUrl != null) {
        updates['resumeUrl'] = _resumeUrl;
      }

      if (_newResumeFile != null) {
        await auth.updateResume(_newResumeFile!);
      }

      await auth.updateUserFields(updates);

      if (mounted) {
        if (auth.errorMessage != null) {
          ToastService().showError("Update failed", 
            message: auth.errorMessage!);
        } else {
          ToastService().showSuccess("Profile updated successfully!");
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// HEADER WITH BACK BUTTON AND SAVE ACTION
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Edit Profile',
                    style: TextStyleHelper.instance.headline22Bold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _saveProfile,
                            child: Text(
                              "Save",
                              style: TextStyleHelper.instance.body16Bold
                                  .copyWith(color: Colors.white),
                            ),
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
                  color: appTheme.whiteA70001,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50.h,
                                backgroundColor: appTheme.gray100,
                                backgroundImage: ImageUtils.getImageProvider(
                                    auth.userModel?.photoURL),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    final picker = ImagePicker();
                                    final image = await picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (image != null && context.mounted) {
                                      await context
                                          .read<AuthProvider>()
                                          .updateProfileImage(File(image.path));
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8.h),
                                    decoration: BoxDecoration(
                                      color: appTheme.indigoA700,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: Icon(Icons.camera_alt,
                                        size: 16.h, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Column(
                            children: [
                              TextButton.icon(
                                onPressed: _isParsing ? null : _magicFill,
                                icon: _isParsing
                                    ? SizedBox(
                                        width: 16.h,
                                        height: 16.h,
                                        child: const CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.auto_awesome, size: 18),
                                label: Text(_isParsing
                                    ? "Analyzing..."
                                    : "Magic Fill from Resume"),
                                style: TextButton.styleFrom(
                                  foregroundColor: appTheme.indigoA700,
                                  backgroundColor: appTheme.indigoA700
                                      .withValues(alpha: 0.05),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.h)),
                                ),
                              ),
                              if (_parsedExperiences != null ||
                                  _parsedProjects != null ||
                                  _parsedCertifications != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Text(
                                    "Pending: ${_parsedExperiences?.length ?? 0} Exp, ${_parsedProjects?.length ?? 0} Proj, ${_parsedCertifications?.length ?? 0} Certs",
                                    style: TextStyleHelper.instance.body12Medium
                                        .copyWith(color: Colors.green[700]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildFieldLabel("Full Name"),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: CustomColors.darkText),
                          decoration: const InputDecoration(
                            hintText: "Enter your full name",
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? "Name is required"
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildFieldLabel("Username"),
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: CustomColors.darkText),
                          decoration: const InputDecoration(
                            hintText: "Enter username",
                            prefixText: "@",
                            prefixStyle:
                                TextStyle(color: CustomColors.textMuted),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? "Username is required"
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildFieldLabel("Bio"),
                        TextFormField(
                          controller: _bioController,
                          style: const TextStyle(color: CustomColors.darkText),
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: "Write something about yourself...",
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFieldLabel("Location"),
                        TextFormField(
                          controller: _locationController,
                          style: const TextStyle(color: CustomColors.darkText),
                          decoration: const InputDecoration(
                            hintText: "e.g. San Francisco, US",
                            prefixIcon:
                                Icon(Icons.location_on_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        _buildFieldLabel("Job Category"),
                        TextFormField(
                          controller: _jobCategoryController,
                          style: const TextStyle(color: CustomColors.darkText),
                          decoration: const InputDecoration(
                            hintText: "e.g. Mobile Developer",
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFieldLabel("Skills"),
                        TextFormField(
                          controller: _skillsController,
                          style: const TextStyle(color: CustomColors.darkText),
                          decoration: const InputDecoration(
                            hintText:
                                "e.g. Flutter, Dart, Firebase (comma separated)",
                            helperText: "Separate multiple skills with commas",
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildFieldLabel("Resume Document"),
                        _buildResumeUploader(auth),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeUploader(AuthProvider auth) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.gray50,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.gray100),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: appTheme.indigoA700, size: 32.h),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resumeUrl != null
                      ? "Resume ready to save"
                      : "No resume selected",
                  style: TextStyleHelper.instance.body14Bold,
                ),
                Text(
                  _resumeUrl != null
                      ? "Will be updated upon saving profile"
                      : "Upload your CV in PDF/DOCX",
                  style: TextStyleHelper.instance.body12Medium
                      .copyWith(color: appTheme.gray500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _magicFill,
            child: Text(_resumeUrl != null ? "Change" : "Upload"),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          color: CustomColors.darkText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

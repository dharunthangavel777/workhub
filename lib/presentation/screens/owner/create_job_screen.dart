import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/models/job_post_model.dart';
import '../../../data/models/project_post_model.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  int _currentStep = 0;
  String _activePostType = 'job'; // 'job' or 'project'

  // --- COMMON FIELDS ---
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final List<String> _requiredSkills = [];
  final _skillController = TextEditingController();

  // --- JOB SPECIFIC FIELDS ---
  String _employmentType = 'Full-time';
  String _workMode = 'Remote';
  final _expMinController = TextEditingController();
  final _expMaxController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyLogoController = TextEditingController();
  final _companyIndustryController = TextEditingController();
  final _companySizeController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _jobSummaryController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  final List<String> _preferredSkills = [];
  final _prefSkillController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  String _salaryType = 'Monthly';
  final _jobLocationController = TextEditingController();
  final _shiftTypeController = TextEditingController();
  final _openingsController = TextEditingController();
  final _educationController = TextEditingController(text: 'Any Graduate');
  final String _applyMethod = 'In-App';
  final bool _resumeRequired = true;
  final List<String> _screeningQuestions = [];
  final _screeningController = TextEditingController();

  // --- PROJECT SPECIFIC FIELDS ---
  String _projectType = 'Fixed';
  String _experienceLevel = 'Intermediate';
  final _projectDescController = TextEditingController();
  final List<String> _deliverables = [];
  final _deliverableController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  String _projectDuration = '1 Month';
  final _projectLocationController = TextEditingController();
  DateTime? _startDate;
  final List<String> _proposalQuestions = [];
  final _proposalQuestionController = TextEditingController();
  final bool _ndaRequired = false;
  final _autoCloseLimitController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _termsAndConditionsController = TextEditingController();
  final _maxApplicationsController = TextEditingController();
  DateTime? _deadlineDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        _companyNameController.text = user.companyName ?? user.displayName;
        _companyWebsiteController.text = user.companyWebsite ?? '';
        _jobLocationController.text = user.location ?? '';
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _skillController.dispose();
    _expMinController.dispose();
    _expMaxController.dispose();
    _companyNameController.dispose();
    _companyLogoController.dispose();
    _companyIndustryController.dispose();
    _companySizeController.dispose();
    _companyWebsiteController.dispose();
    _jobSummaryController.dispose();
    _responsibilitiesController.dispose();
    _prefSkillController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _jobLocationController.dispose();
    _shiftTypeController.dispose();
    _openingsController.dispose();
    _educationController.dispose();
    _screeningController.dispose();
    _projectDescController.dispose();
    _deliverableController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _proposalQuestionController.dispose();
    _autoCloseLimitController.dispose();
    _depositAmountController.dispose();
    _termsAndConditionsController.dispose();
    _maxApplicationsController.dispose();
    _projectLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: Text("Post ${_activePostType == 'job' ? 'Job' : 'Project'}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildPostTypeToggle(),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: CustomColors.primaryBlue,
                  onSurface: CustomColors.darkText,
                ),
              ),
              child: Stepper(
                key: Key(_activePostType),
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < _getSteps().length - 1) {
                    setState(() => _currentStep++);
                  } else {
                    _submitPost();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
                onStepTapped: (step) => setState(() => _currentStep = step),
                steps: _getSteps(),
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CustomColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              _currentStep == _getSteps().length - 1
                                  ? "Post Now"
                                  : "Next",
                            ),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: details.onStepCancel,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.black12),
                              ),
                              child: const Text("Back"),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeToggle() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'job',
            label: Text('Traditional Job'),
            icon: Icon(Icons.business_center_outlined),
          ),
          ButtonSegment(
            value: 'project',
            label: Text('Freelance Project'),
            icon: Icon(Icons.bolt),
          ),
        ],
        selected: {_activePostType},
        onSelectionChanged: (val) {
          setState(() {
            _activePostType = val.first;
            _currentStep = 0;
            // Clear limit fields when switching
            _maxApplicationsController.clear();
            _deadlineDate = null;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return CustomColors.primaryBlue.withValues(alpha: 0.2);
            }
            return Colors.transparent;
          }),
        ),
      ),
    );
  }

  List<Step> _getSteps() {
    if (_activePostType == 'job') {
      return _getJobSteps();
    } else {
      return _getProjectSteps();
    }
  }

  List<Step> _getJobSteps() {
    return [
      Step(
        title: const Text("Basic"),
        isActive: _currentStep >= 0,
        content: Column(
          children: [
            const _Label("Job Title *"),
            _textField(_titleController, "e.g. Senior UI Designer",
                maxLength: 18),
            const SizedBox(height: 16),
            const _Label("Job Category *"),
            _categoryDropdown(),
            const SizedBox(height: 16),
            const _Label("Education *"),
            _textField(_educationController, "e.g. B.Tech, Any Graduate"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label("Employment Type"),
                      _dropdown(
                          ['Full-time', 'Part-time', 'Internship', 'Contract'],
                          _employmentType,
                          (v) => setState(
                              () => _employmentType = v ?? 'Full-time')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label("Work Mode"),
                      _dropdown(['On-site', 'Remote', 'Hybrid'], _workMode,
                          (v) => setState(() => _workMode = v ?? 'On-site')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _labeledTextField(
                        "Min Experience", _expMinController, "Years",
                        keyboard: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                    child: _labeledTextField(
                        "Max Experience", _expMaxController, "Years",
                        keyboard: TextInputType.number)),
              ],
            ),
          ],
        ),
      ),
      Step(
        title: const Text("Company"),
        isActive: _currentStep >= 1,
        content: Column(
          children: [
            _labeledTextField(
                "Company Name *", _companyNameController, "e.g. Acme Corp"),
            const SizedBox(height: 16),
            _labeledTextField("Company Website", _companyWebsiteController,
                "https://acme.inc"),
            const SizedBox(height: 16),
            _labeledTextField(
                "Industry *", _companyIndustryController, "e.g. Software, IT"),
            const SizedBox(height: 16),
            const _Label("Company Size"),
            _dropdown(
                ['1-10', '11-50', '51-200', '201-500', '500+'],
                _companySizeController.text.isEmpty
                    ? '11-50'
                    : _companySizeController.text,
                (v) => setState(() => _companySizeController.text = v ?? '')),
          ],
        ),
      ),
      Step(
        title: const Text("About"),
        isActive: _currentStep >= 2,
        content: Column(
          children: [
            _labeledTextField("Job Summary *", _jobSummaryController,
                "Briefly describe the role...",
                maxLines: 3),
            const SizedBox(height: 16),
            _labeledTextField("Responsibilities *", _responsibilitiesController,
                "List key duties...",
                maxLines: 5),
            const SizedBox(height: 16),
            const _Label("Required Skills *"),
            _listInput(_skillController, _requiredSkills, "Add Skill"),
          ],
        ),
      ),
      Step(
        title: const Text("Salary"),
        isActive: _currentStep >= 3,
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _labeledTextField(
                        "Min Salary", _salaryMinController, "Amount",
                        keyboard: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                    child: _labeledTextField(
                        "Max Salary", _salaryMaxController, "Amount",
                        keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            const _Label("Salary Cycle"),
            _dropdown(['Monthly', 'Annual', 'Negotiable'], _salaryType,
                (v) => setState(() => _salaryType = v ?? 'Monthly')),
            const SizedBox(height: 16),
            _labeledTextField(
                "Location *", _jobLocationController, "City, State"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _labeledTextField(
                    "Total Vacancies *",
                    _openingsController,
                    "e.g. 5",
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _labeledTextField(
                    "Max Applications",
                    _maxApplicationsController,
                    "e.g. 50 (Optional)",
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label("Deadline Date"),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _deadlineDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _deadlineDate != null
                                ? "${_deadlineDate!.toLocal()}".split(' ')[0]
                                : "Select Date",
                            style: TextStyle(
                              color: _deadlineDate != null
                                  ? CustomColors.darkText
                                  : CustomColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Step> _getProjectSteps() {
    return [
      Step(
        title: const Text("Basics"),
        isActive: _currentStep >= 0,
        content: Column(
          children: [
            _labeledTextField(
                "Project Title *", _titleController, "e.g. Mobile App Redesign",
                maxLength: 18),
            const SizedBox(height: 16),
            _labeledTextField(
                "Company Name", _companyNameController, "e.g. Acme Studio"),
            const SizedBox(height: 16),
            const _Label("Category *"),
            _categoryDropdown(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label("Project Type"),
                      _dropdown(
                          ['Fixed', 'Hourly'],
                          _projectType,
                          (v) => setState(
                              () => _projectType = v ?? 'Fixed-price')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label("Exp Level"),
                      _dropdown(
                          ['Beginner', 'Intermediate', 'Expert'],
                          _experienceLevel,
                          (v) => setState(
                              () => _experienceLevel = v ?? 'Entry Level')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Step(
        title: const Text("Details"),
        isActive: _currentStep >= 1,
        content: Column(
          children: [
            _labeledTextField("Project Brief *", _projectDescController,
                "Detail your requirements...",
                maxLines: 6),
            const SizedBox(height: 16),
            const _Label("Deliverables *"),
            _listInput(
                _deliverableController, _deliverables, "Add Deliverable"),
            const SizedBox(height: 16),
            const _Label("Required Skills *"),
            _listInput(_skillController, _requiredSkills, "Add Skill"),
          ],
        ),
      ),
      Step(
        title: const Text("Budget"),
        isActive: _currentStep >= 2,
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _labeledTextField(
                        "Min Budget *", _budgetMinController, "e.g. 5000",
                        keyboard: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                    child: _labeledTextField(
                        "Max Budget *", _budgetMaxController, "e.g. 10000",
                        keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            const _Label("Project Duration"),
            _dropdown(
                ['1 Week', '2 Weeks', '1 Month', '3 Months', '6+ Months'],
                _projectDuration,
                (v) => setState(
                    () => _projectDuration = v ?? 'Less than 1 month')),
            const SizedBox(height: 16),
            _labeledTextField("Project Location *", _projectLocationController,
                "City, State"),
            const SizedBox(height: 16),
            _labeledTextField("Terms & Conditions *",
                _termsAndConditionsController, "Detail the project terms...",
                maxLines: 5),
            const SizedBox(height: 16),
            const _Label("Application Limits"),
            Row(
              children: [
                Expanded(
                  child: _labeledTextField(
                    "Max Applications",
                    _maxApplicationsController,
                    "e.g. 50 (Optional)",
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label("Deadline Date"),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _deadlineDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _deadlineDate != null
                                ? "${_deadlineDate!.toLocal()}".split(' ')[0]
                                : "Select Date",
                            style: TextStyle(
                              color: _deadlineDate != null
                                  ? CustomColors.darkText
                                  : CustomColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  void _submitPost() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Posting..."), duration: Duration(seconds: 1)));

    try {
      if (_activePostType == 'job') {
        final job = JobPostModel(
          id: '',
          ownerId: user.uid,
          jobTitle: _titleController.text,
          jobCategory: _categoryController.text,
          employmentType: _employmentType,
          workMode: _workMode,
          experienceMin: int.tryParse(_expMinController.text) ?? 0,
          experienceMax: int.tryParse(_expMaxController.text) ?? 0,
          ownerName: user.displayName,
          ownerPhoto: user.photoURL,
          companyName: _companyNameController.text,
          companyLogo:
              user.photoURL, // Or use a separate logo field if available
          companyIndustry: _companyIndustryController.text,
          companySize: _companySizeController.text,
          companyWebsite: _companyWebsiteController.text,
          jobSummary: _jobSummaryController.text,
          responsibilities: _responsibilitiesController.text,
          requiredSkills: _requiredSkills,
          preferredSkills: _preferredSkills,
          salaryMin: int.tryParse(_salaryMinController.text),
          salaryMax: int.tryParse(_salaryMaxController.text),
          salaryType: _salaryType,
          jobLocation: _jobLocationController.text,
          shiftType: _shiftTypeController.text,
          education: _educationController.text,
          openings: int.tryParse(_openingsController.text) ?? 1,
          applyMethod: _applyMethod,
          resumeRequired: _resumeRequired,
          screeningQuestions: _screeningQuestions,
          maxApplications: int.tryParse(_maxApplicationsController.text),
          deadlineDate: _deadlineDate,
          createdAt: DateTime.now(),
        );
        await context.read<JobProvider>().createJobPost(job);
      } else {
        final project = ProjectPostModel(
          id: '',
          ownerId: user.uid,
          ownerName: user.displayName,
          ownerPhoto: user.photoURL,
          companyName: _companyNameController.text.isNotEmpty
              ? _companyNameController.text
              : (user.companyName ?? user.displayName),
          companyLogo: user.photoURL,
          projectTitle: _titleController.text,
          projectCategory: _categoryController.text,
          projectType: _projectType,
          experienceLevel: _experienceLevel,
          projectLocation: _projectLocationController.text,
          workMode: 'Remote', // Defaulted for projects
          projectDescription: _projectDescController.text,
          deliverables: _deliverables,
          requiredSkills: _requiredSkills,
          budgetMin: int.tryParse(_budgetMinController.text) ?? 0,
          budgetMax: int.tryParse(_budgetMaxController.text) ?? 0,
          projectDuration: _projectDuration,
          startDate: _startDate,
          proposalQuestions: _proposalQuestions,
          ndaRequired: _ndaRequired,
          autoCloseLimit: int.tryParse(_autoCloseLimitController.text),
          maxApplications: int.tryParse(_maxApplicationsController.text),
          deadlineDate: _deadlineDate,
          createdAt: DateTime.now(),
          depositAmount: 0, // No deposit needed at post creation
          termsAndConditions: _termsAndConditionsController.text,
        );
        await context.read<JobProvider>().createProjectPost(project);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "${_activePostType == 'job' ? 'Job' : 'Project'} Posted Successfully!"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _textField(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboard, int? maxLength}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboard,
      style: const TextStyle(color: CustomColors.darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: CustomColors.textMuted),
        contentPadding: const EdgeInsets.all(16),
        counterText: maxLength != null ? null : "", // Hide counter if no limit
      ),
    );
  }

  Widget _labeledTextField(
      String label, TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboard, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        _textField(controller, hint,
            maxLines: maxLines, keyboard: keyboard, maxLength: maxLength),
      ],
    );
  }

  Widget _dropdown(
      List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CustomColors.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: CustomColors.lightCard,
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: const TextStyle(color: CustomColors.darkText))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return _dropdown([
      'IT',
      'Design',
      'Marketing',
      'Writing',
      'Finance',
      'BPO',
      'Sales',
      'Other'
    ], _categoryController.text.isEmpty ? 'IT' : _categoryController.text,
        (v) => setState(() => _categoryController.text = v ?? ''));
  }

  Widget _listInput(
      TextEditingController controller, List<String> list, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onSubmitted: (v) {
            if (v.isNotEmpty) {
              setState(() {
                list.add(v);
                controller.clear();
              });
            }
          },
          style: const TextStyle(color: CustomColors.darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: CustomColors.textMuted),
            suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle,
                    color: CustomColors.primaryBlue),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      list.add(controller.text);
                      controller.clear();
                    });
                  }
                }),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: list
              .map((e) => Chip(
                    label: Text(e,
                        style:
                            const TextStyle(color: CustomColors.primaryBlue)),
                    backgroundColor:
                        CustomColors.primaryBlue.withValues(alpha: 0.1),
                    onDeleted: () => setState(() => list.remove(e)),
                    deleteIconColor: CustomColors.primaryBlue,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4),
      child: Text(text,
          style: const TextStyle(
              color: CustomColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.bold)),
    );
  }
}

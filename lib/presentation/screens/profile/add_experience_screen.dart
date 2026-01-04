import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../data/models/experience_model.dart';
import '../../../logic/providers/auth_provider.dart';

class AddExperienceScreen extends StatefulWidget {
  const AddExperienceScreen({super.key});

  @override
  State<AddExperienceScreen> createState() => _AddExperienceScreenState();
}

class _AddExperienceScreenState extends State<AddExperienceScreen> {
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _durationController = TextEditingController();
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(title: const Text("Add Experience")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _TextField(
              controller: _titleController,
              label: "Job Title",
              hint: "e.g. Senior Flutter Developer",
            ),
            const SizedBox(height: 20),
            _TextField(
              controller: _companyController,
              label: "Company",
              hint: "e.g. Google",
            ),
            const SizedBox(height: 20),
            _TextField(
              controller: _durationController,
              label: "Duration",
              hint: "e.g. Jan 2020 - Present",
            ),
            const SizedBox(height: 20),
            _TextField(
              controller: _descController,
              label: "Description",
              hint: "What did you achieve?",
              maxLines: 4,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) return;
                  final exp = ExperienceModel(
                    title: _titleController.text,
                    company: _companyController.text,
                    duration: _durationController.text,
                    description: _descController.text,
                  );

                  final user = context.read<AuthProvider>().userModel;
                  if (user != null) {
                    final updatedExps = List<ExperienceModel>.from(
                      user.experiences ?? [],
                    );
                    updatedExps.add(exp);
                    // We need a method in AuthProvider to update user data
                    final auth = context.read<AuthProvider>();
                    await auth.updateExperiences(updatedExps);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text("Save Experience"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/data/models/user_model.dart';
import 'package:work_hub/theme/custom_colors.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';

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
  late TextEditingController _companyNameController;
  late TextEditingController _companyWebsiteController;
  late TextEditingController _managerNameController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    _nameController = TextEditingController(text: user?.displayName);
    _usernameController = TextEditingController(text: user?.username);
    _bioController = TextEditingController(text: user?.bio);
    _locationController = TextEditingController(text: user?.location);
    _jobCategoryController = TextEditingController(text: user?.jobCategory);
    _skillsController = TextEditingController(text: user?.skills?.join(', '));
    _companyNameController = TextEditingController(text: user?.companyName);
    _companyWebsiteController =
        TextEditingController(text: user?.companyWebsite);
    _managerNameController = TextEditingController(text: user?.managerName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _jobCategoryController.dispose();
    _skillsController.dispose();
    _companyNameController.dispose();
    _companyWebsiteController.dispose();
    _managerNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();

      final isOwner = auth.userModel?.role == UserRole.businessOwner;

      final updates = <String, dynamic>{
        'displayName': _nameController.text.trim(),
        'location': _locationController.text.trim(),
      };

      if (isOwner) {
        updates.addAll({
          'companyName': _companyNameController.text.trim(),
          'companyWebsite': _companyWebsiteController.text.trim(),
          'managerName': _managerNameController.text.trim(),
        });
      } else {
        updates.addAll({
          'username': _usernameController.text.trim(),
          'bio': _bioController.text.trim(),
          'jobCategory': _jobCategoryController.text.trim(),
          'skills': _skillsController.text.trim().isNotEmpty
              ? _skillsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
              : null,
        });
      }

      await auth.updateUserFields(updates);

      if (mounted) {
        if (auth.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (auth.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                "Save",
                style: TextStyle(
                  color: CustomColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (auth.userModel?.role != UserRole.businessOwner) ...[
                _buildFieldLabel("Full Name"),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: CustomColors.darkText),
                  decoration: const InputDecoration(
                    hintText: "Enter your full name",
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Name is required" : null,
                ),
                const SizedBox(height: 20),
              ],
              if (auth.userModel?.role != UserRole.businessOwner) ...[
                _buildFieldLabel("Username"),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: CustomColors.darkText),
                  decoration: const InputDecoration(
                    hintText: "Enter username",
                    prefixText: "@",
                    prefixStyle: TextStyle(color: CustomColors.textMuted),
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
              ],
              if (auth.userModel?.role == UserRole.businessOwner) ...[
                _buildFieldLabel("Company Name"),
                TextFormField(
                  controller: _companyNameController,
                  style: const TextStyle(color: CustomColors.darkText),
                  decoration: const InputDecoration(
                    hintText: "Enter company name",
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? "Company name is required"
                      : null,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel("Company Website"),
                TextFormField(
                  controller: _companyWebsiteController,
                  style: const TextStyle(color: CustomColors.darkText),
                  decoration: const InputDecoration(
                    hintText: "e.g. https://company.com",
                  ),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel("Hiring Manager Name"),
                TextFormField(
                  controller: _managerNameController,
                  style: const TextStyle(color: CustomColors.darkText),
                  decoration: const InputDecoration(
                    hintText: "Enter manager name",
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _buildFieldLabel("Location"),
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: CustomColors.darkText),
                decoration: const InputDecoration(
                  hintText: "e.g. San Francisco, US",
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              if (auth.userModel?.role != UserRole.businessOwner) ...[
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
                    hintText: "e.g. Flutter, Dart, Firebase (comma separated)",
                    helperText: "Separate multiple skills with commas",
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
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

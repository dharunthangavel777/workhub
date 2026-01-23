import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import '../../../config/app_export.dart';

class ClientProfileCompletionScreen extends StatefulWidget {
  const ClientProfileCompletionScreen({super.key});

  @override
  State<ClientProfileCompletionScreen> createState() =>
      _ClientProfileCompletionScreenState();
}

class _ClientProfileCompletionScreenState
    extends State<ClientProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().completeOwnerProfile(
          companyName: _companyNameController.text.trim(),
          managerName: _managerNameController.text.trim(),
          location: _locationController.text.trim(),
          companyWebsite: _websiteController.text.trim(),
        );

    if (success && mounted) {
      // After becoming a hirer, switch mode or navigate relevantly
      // For now, we pop or go to home. RootWrapper might handle role change if updated.
      // Assuming completeOwnerProfile updates the role or data needed.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile completed! You are now a hirer.')),
      );
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Become a Hirer'), elevation: 0),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Setup your business profile to start hiring.',
                      style: TextStyleHelper.instance.body16Regular,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _managerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Hiring Manager Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website (Optional)',
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
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
                      child: Text(
                        'Start Hiring',
                        style: TextStyleHelper.instance.body16SemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../data/models/dispute_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/job_provider.dart';

class DisputeScreen extends StatefulWidget {
  final String projectId;
  final String currentRole; // 'owner' or 'worker'

  const DisputeScreen({
    super.key,
    required this.projectId,
    required this.currentRole,
  });

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final List<File> _evidenceFiles = [];

  final List<String> _reasons = [
    'Work quality not as described',
    'Missed deadlines',
    'Unresponsive',
    'Payment issues',
    'Other',
  ];

  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text("Raise Dispute"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: CustomColors.darkText,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWarningCard(),
              const SizedBox(height: 32),
              const Text(
                "Why are you raising this dispute?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                items: _reasons
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
                validator: (value) =>
                    value == null ? 'Please select a reason' : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Describe the issue in detail",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.length < 20) {
                    return 'Please provide at least 20 characters detail';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Provide context, dates, and specific incidents...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildEvidenceSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDispute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit Dispute",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Our support team will review your dispute within 24-48 hours.",
                  style: TextStyle(color: CustomColors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Raising a dispute will pause all project payments until resolved. Please try to resolve the issue directly with the other party first.",
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReason == null) return;

    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final List<String> evidenceUrls = [];
      final jobProvider = context.read<JobProvider>();

      for (var file in _evidenceFiles) {
        final url = await jobProvider.uploadDisputeFile(
          projectId: widget.projectId,
          file: file,
          fileName: file.path.split('/').last,
        );
        evidenceUrls.add(url);
      }

      final dispute = DisputeInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: widget.projectId,
        raisedBy: user.uid,
        raisedByRole: widget.currentRole,
        reason: _selectedReason!,
        description: _descriptionController.text,
        evidence: evidenceUrls,
        status: DisputeStatus.open,
      );

      await context.read<JobProvider>().raiseDispute(dispute);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dispute submitted. Support will contact you shortly."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Evidence & Attachments",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CustomColors.darkText,
              ),
            ),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add_a_photo, size: 20),
              label: const Text("Add"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_evidenceFiles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: const Column(
              children: [
                Icon(Icons.cloud_upload_outlined, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  "Upload screenshots, documents, or logs",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _evidenceFiles.asMap().entries.map((entry) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                      image: entry.value.path.toLowerCase().endsWith('.jpg') ||
                              entry.value.path.toLowerCase().endsWith('.png') ||
                              entry.value.path.toLowerCase().endsWith('.jpeg')
                          ? DecorationImage(
                              image: FileImage(entry.value),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: entry.value.path.toLowerCase().endsWith('.jpg') ||
                            entry.value.path.toLowerCase().endsWith('.png') ||
                            entry.value.path.toLowerCase().endsWith('.jpeg')
                        ? null
                        : const Icon(Icons.insert_drive_file,
                            color: Colors.grey),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _evidenceFiles.removeAt(entry.key)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _evidenceFiles.addAll(result.paths.map((path) => File(path!)));
      });
    }
  }
}

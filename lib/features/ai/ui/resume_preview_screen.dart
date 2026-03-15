import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/resume_parse_provider.dart';
import '../domain/models/resume_data_model.dart';
import '../ui/widgets/resume_score_card.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../../../core/services/toast_service.dart';
import '../../auth/logic/auth_controller.dart';
import '../../profile/domain/models/experience.dart';
import '../../profile/domain/models/skill.dart';

class ResumePreviewScreen extends StatefulWidget {
  const ResumePreviewScreen({super.key});

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeParseProvider>();
    final data = provider.parsedData;
    final score = provider.score;

    if (data == null) {
      return const Scaffold(body: Center(child: Text('No data found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Parsed Data'),
        actions: [
          TextButton(
            onPressed: () => _applyToProfile(context, data),
            child: const Text('Save',
                style: TextStyle(color: CustomColors.primaryBlue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (score != null) ResumeScoreCard(score: score),
            _buildSection(
              title: 'Personal Info',
              children: [
                _buildInfoRow('Name', data.name ?? 'Not found'),
                _buildInfoRow('Email', data.email ?? 'Not found'),
                _buildInfoRow('Phone', data.phone ?? 'Not found'),
                _buildInfoRow('Location', data.location ?? 'Not found'),
                _buildInfoRow('Category', data.category ?? 'Not found'),
              ],
            ),
            _buildSection(
              title: 'Skills',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.skills.allSkills.map((s) {
                    return Chip(
                      label: Text(s.name),
                      backgroundColor: CustomColors.primaryBlue.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ),
            _buildSection(
              title: 'Summary',
              children: [
                Text(data.bio ?? 'No summary extracted.',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            if (data.workExperience.isNotEmpty)
              _buildSection(
                title: 'Work Experience',
                children: data.workExperience
                    .map((exp) => ListTile(
                          title: Text(exp.title ?? 'Role'),
                          subtitle: Text(
                              '${exp.company ?? 'Company'} • ${exp.duration ?? ''}'),
                          contentPadding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => _applyToProfile(context, data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply to My Profile'),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _applyToProfile(BuildContext context, ResumeData data) async {
    final auth = context.read<AuthProvider>();

    // Map ResumeData to User Fields
    final updates = <String, dynamic>{};
    if (data.name != null) updates['displayName'] = data.name;
    if (data.bio != null) updates['bio'] = data.bio;
    if (data.location != null) {
      updates['location'] = data.location;
    }
    if (data.category != null) {
      updates['jobCategory'] = data.category;
    }

    if (data.skills.allSkills.isNotEmpty) {
      updates['skills'] = data.skills.allSkills
          .map((s) => SkillModel(
                name: s.name,
                isVerified: true,
                verificationSource: 'ai',
                confidence: s.confidence,
              ).toMap())
          .toList();
    }

    if (data.workExperience.isNotEmpty) {
      updates['experiences'] = data.workExperience
          .map((exp) => ExperienceModel(
                title: exp.title ?? '',
                company: exp.company ?? '',
                duration: exp.duration ?? '',
                description: exp.description ?? '',
              ).toMap())
          .toList();
    }

    // Add certifications if available
    if (data.certifications.isNotEmpty) {
      updates['certifications'] = data.certifications
          .map((c) => {
                'name': c.name,
                'issuer': c.issuer,
                'date': c.date,
              })
          .toList();
    }

    final success = await auth.updateUserFields(updates);

    if (mounted) {
      if (success != false) {
        ToastService().showSuccess('Profile updated', message: 'Your profile has been enhanced with AI insights!');
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else {
        ToastService().showError('Update failed', message: 'Failed to update profile. Please try again.');
      }
    }
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CustomColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}





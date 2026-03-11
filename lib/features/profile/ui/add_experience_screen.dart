import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/features/profile/domain/models/experience.dart';

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
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _durationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// HEADER WITH BACK BUTTON
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Add Experience',
                    style: TextStyleHelper.instance.headline22Bold.copyWith(
                      color: Colors.white,
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
                  color: appTheme.white_A700_01,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.h),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: "Job Title",
                        hint: "e.g. Senior Flutter Developer",
                      ),
                      SizedBox(height: 20.h),
                      _buildTextField(
                        controller: _companyController,
                        label: "Company",
                        hint: "e.g. Google",
                      ),
                      SizedBox(height: 20.h),
                      _buildTextField(
                        controller: _durationController,
                        label: "Duration",
                        hint: "e.g. Jan 2020 - Present",
                      ),
                      SizedBox(height: 20.h),
                      _buildTextField(
                        controller: _descController,
                        label: "Description",
                        hint: "What did you achieve?",
                        maxLines: 4,
                      ),
                      SizedBox(height: 40.h),
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
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
                              
                              final auth = context.read<AuthProvider>();
                              await auth.updateExperiences(updatedExps);
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.indigo_A700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.h),
                            ),
                          ),
                          child: Text(
                            "Save Experience",
                            style: TextStyleHelper.instance.body16Bold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleHelper.instance.body14Bold.copyWith(
            color: appTheme.gray_900,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyleHelper.instance.body14Medium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyleHelper.instance.body14Medium.copyWith(color: appTheme.gray_400),
            filled: true,
            fillColor: appTheme.gray_50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.h),
              borderSide: BorderSide(color: appTheme.gray_200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.h),
              borderSide: BorderSide(color: appTheme.gray_200),
            ),
          ),
        ),
      ],
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';

class AddPortfolioScreen extends StatefulWidget {
  const AddPortfolioScreen({super.key});

  @override
  State<AddPortfolioScreen> createState() => _AddPortfolioScreenState();
}

class _AddPortfolioScreenState extends State<AddPortfolioScreen> {
  final _titleController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
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
                    'Add to Portfolio',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Project Preview",
                        style: TextStyleHelper.instance.body14Bold.copyWith(
                          color: appTheme.gray_900,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      
                      /// IMAGE PICKER CONTAINER
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: appTheme.gray_50,
                            borderRadius: BorderRadius.circular(20.h),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            border: Border.all(
                              color: _imageFile != null ? Colors.transparent : appTheme.gray_200,
                              width: 1,
                            ),
                          ),
                          child: _imageFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48.h,
                                      color: appTheme.gray_400,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Tap to upload project image",
                                      style: TextStyleHelper.instance.body14Medium.copyWith(
                                        color: appTheme.gray_500,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      
                      SizedBox(height: 24.h),

                      /// PROJECT TITLE FIELD
                      _buildTextField(
                        controller: _titleController,
                        label: "Project Title",
                        hint: "e.g. E-commerce App Redesign",
                      ),

                      SizedBox(height: 40.h),

                      /// SUBMIT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: _isUploading
                              ? null
                              : () async {
                                  if (_titleController.text.isEmpty || _imageFile == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please provide a title and an image")),
                                    );
                                    return;
                                  }

                                  setState(() => _isUploading = true);
                                  final auth = context.read<AuthProvider>();
                                  await auth.addPortfolioItem(
                                    _titleController.text,
                                    _imageFile!,
                                  );
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.indigo_A700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.h),
                            ),
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Add to Portfolio",
                                  style: TextStyleHelper.instance.body16Bold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 20.h),
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
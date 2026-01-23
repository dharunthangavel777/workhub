import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:work_hub/config/app_export.dart';
import 'package:work_hub/logic/providers/ad_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import 'package:work_hub/theme/theme_helper.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({super.key});

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _ctaLinkController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _durationController =
      TextEditingController(); // Days

  File? _videoFile;
  final ImagePicker _picker = ImagePicker();
  String _selectedCtaLabel = 'Learn More';
  final List<String> _ctaOptions = [
    'Learn More',
    'Apply Now',
    'Visit Profile',
    'Sign Up',
    'Shop Now'
  ];

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery, maxDuration: const Duration(minutes: 1));
    if (video != null) {
      setState(() {
        _videoFile = File(video.path);
      });
    }
  }

  void _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_videoFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a video for the ad")),
        );
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) return;

    final double amount = double.parse(_budgetController.text);
    // Wallet check skipped for free campaigns
    // if (user.walletBalance < amount) {
    //   _showLowBalanceDialog();
    //   return;
    // }

    try {
      await context.read<AdProvider>().createCampaign(
            ownerId: user.uid,
            videoFile: _videoFile!,
            caption: _captionController.text,
            ctaLabel: _selectedCtaLabel,
            ctaLink: _ctaLinkController.text,
            budget: amount,
            durationDays: int.parse(_durationController.text),
            username: user
                .displayName, // fallback to display name if username invalid
            userPhotoUrl: user.photoURL ?? '',
          );

      // Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Campaign submitted successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create campaign: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      appBar: AppBar(
        title: Text("Create Campaign",
            style: TextStyleHelper.instance.headline22Bold),
        centerTitle: true,
        backgroundColor: appTheme.white_A700,
        elevation: 0,
        iconTheme: IconThemeData(color: appTheme.indigo_A700),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Picker
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: 200.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appTheme.gray_100,
                    borderRadius: BorderRadius.circular(16.h),
                    border: Border.all(
                        color: appTheme.gray_300, style: BorderStyle.solid),
                  ),
                  child: _videoFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16.h),
                              child: Container(
                                color: Colors.black,
                                child: const Center(
                                    child: Icon(Icons.play_circle_fill,
                                        color: Colors.white, size: 50)),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.change_circle,
                                    color: Colors.white),
                                onPressed: _pickVideo,
                              ),
                            )
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_library,
                                size: 48.h, color: appTheme.indigo_A700),
                            SizedBox(height: 12.h),
                            Text("Tap to upload video",
                                style: TextStyleHelper.instance.body14Bold),
                            Text("Max length: 60s",
                                style: TextStyleHelper.instance.body12Medium
                                    .copyWith(color: appTheme.gray_500)),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 24.h),

              Text("Campaign Details",
                  style: TextStyleHelper.instance.body16Bold),
              SizedBox(height: 16.h),

              // Caption
              TextFormField(
                controller: _captionController,
                decoration: _inputDecoration("Ad Caption / Description"),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16.h),

              // CTA Label
              DropdownButtonFormField<String>(
                value: _selectedCtaLabel,
                items: _ctaOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCtaLabel = v!),
                decoration: _inputDecoration("Call to Action Label"),
              ),
              SizedBox(height: 16.h),

              // CTA Link
              TextFormField(
                controller: _ctaLinkController,
                decoration: _inputDecoration("Destination URL (Optional)"),
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 16.h),

              // Budget & Duration
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      decoration: _inputDecoration("Total Budget (₹)"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: _inputDecoration("Duration (Days)"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Submit
              SizedBox(
                width: double.infinity,
                child:
                    Consumer<AdProvider>(builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appTheme.indigo_A700,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.h)),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Launch Campaign",
                            style: TextStyleHelper.instance.body16Bold
                                .copyWith(color: Colors.white)),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyleHelper.instance.body14Medium
          .copyWith(color: appTheme.gray_500),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.h),
          borderSide: BorderSide(color: appTheme.gray_300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.h),
          borderSide: BorderSide(color: appTheme.gray_300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.h),
          borderSide: BorderSide(color: appTheme.indigo_A700)),
      filled: true,
      fillColor: appTheme.gray_50,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/core/theme/text_style_helper.dart';
import 'package:work_hub/core/theme/theme_helper.dart';
import 'package:work_hub/core/extensions/context_extensions.dart';
import 'package:work_hub/constants/app_strings.dart';
import 'package:work_hub/core/theme/custom_colors.dart';

class BecomeOwnerScreen extends StatefulWidget {
  const BecomeOwnerScreen({super.key});

  @override
  State<BecomeOwnerScreen> createState() => _BecomeOwnerScreenState();
}

class _BecomeOwnerScreenState extends State<BecomeOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _businessTypeController.dispose();
    _websiteController.dispose();
    _managerNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().submitOwnerRequest({
      'companyName': _companyNameController.text.trim(),
      'businessType': _businessTypeController.text.trim(),
      'website': _websiteController.text.trim(),
      'managerName': _managerNameController.text.trim(),
      'description': _descriptionController.text.trim(),
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AuthProvider>().errorMessage ??
                AppStrings.submitError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: appTheme.white_A700_01,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
        title: Text(AppStrings.requestSubmitted,
            style: TextStyleHelper.instance.body18Bold),
        content: Text(AppStrings.requestSubmittedDesc,
            style: TextStyleHelper.instance.body14Medium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(AppStrings.ok,
                style: TextStyle(
                    color: appTheme.indigo_A700, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: Column(
        children: [
          // CUSTOM PROFESSIONAL HEADER
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                    "Business Center",
                    style: TextStyleHelper.instance.headline22Bold
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.h)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.h)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WELCOME SECTION
                        Text(
                          "Scale Your Business",
                          style: TextStyleHelper.instance.headline22Bold
                              .copyWith(color: appTheme.indigo_A700),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Join our elite network of verified business owners and hire the best talent.",
                          style: TextStyleHelper.instance.body14Medium
                              .copyWith(color: appTheme.gray_500),
                        ),

                        SizedBox(height: 32.h),

                        // BENEFITS SECTION
                        _buildBenefitItem(
                          icon: Icons.verified_user_outlined,
                          title: "Verified Hiring",
                          desc:
                              "Get a verified badge for your company profile.",
                        ),
                        SizedBox(height: 16.h),
                        _buildBenefitItem(
                          icon: Icons.groups_outlined,
                          title: "Top 1% Talent",
                          desc:
                              "Access highly skilled freelancers and workers.",
                        ),

                        SizedBox(height: 40.h),
                        Divider(color: appTheme.gray_100, thickness: 1.5.h),
                        SizedBox(height: 32.h),

                        Text(
                          "Company Details",
                          style: TextStyleHelper.instance.body16Bold
                              .copyWith(color: appTheme.gray_900),
                        ),
                        SizedBox(height: 24.h),

                        _buildProfessionalField(
                          label: "Official Company Name",
                          controller: _companyNameController,
                          hint: "e.g. Acme Innovations Ltd.",
                          icon: Icons.business,
                        ),
                        SizedBox(height: 20.h),

                        Row(
                          children: [
                            Expanded(
                              child: _buildProfessionalField(
                                label: "Industry Type",
                                controller: _businessTypeController,
                                hint: "e.g. Tech",
                                icon: Icons.category_outlined,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildProfessionalField(
                                label: "Manager Name",
                                controller: _managerNameController,
                                hint: "Your name",
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        _buildProfessionalField(
                          label: "Website / LinkedIn (Optional)",
                          controller: _websiteController,
                          hint: "https://www.company.com",
                          icon: Icons.link,
                        ),
                        SizedBox(height: 20.h),

                        _buildProfessionalField(
                          label: "Business Description",
                          controller: _descriptionController,
                          hint:
                              "Tell us about your company and hiring needs...",
                          icon: Icons.description_outlined,
                          maxLines: 4,
                        ),

                        SizedBox(height: 48.h),

                        SizedBox(
                          width: double.infinity,
                          height: 58.h,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appTheme.indigo_A700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.h)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 3),
                                  )
                                : Text(
                                    "Submit Business Request",
                                    style: TextStyleHelper.instance.body16Bold
                                        .copyWith(color: Colors.white),
                                  ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
      {required IconData icon, required String title, required String desc}) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: appTheme.indigo_A700.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: appTheme.indigo_A700, size: 24.h),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyleHelper.instance.body14Bold),
                SizedBox(height: 4.h),
                Text(desc,
                    style: TextStyleHelper.instance.body10Medium
                        .copyWith(color: appTheme.gray_500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyleHelper.instance.body12Bold
                .copyWith(color: appTheme.gray_700)),
        SizedBox(height: 10.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (v) => (v == null || v.isEmpty) ? "Field required" : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyleHelper.instance.body14Regular
                .copyWith(color: appTheme.gray_400),
            prefixIcon: Icon(icon, color: appTheme.gray_400, size: 20.h),
            fillColor: appTheme.gray_50,
            filled: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.h),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.h),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.h),
              borderSide: BorderSide(color: appTheme.indigo_A700, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: maxLines > 1 ? 16.h : 0),
          ),
        ),
      ],
    );
  }
}

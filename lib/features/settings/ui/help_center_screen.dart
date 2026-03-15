import 'package:qwok/core/config/app_export.dart';
import 'package:qwok/core/services/toast_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedIssueType;
  final _descriptionController = TextEditingController();

  final List<String> _issueTypes = [
    "Account Access",
    "Payment & Billing",
    "Job Posting Issue",
    "Technical Bug",
    "Report a User",
    "Other"
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitSupportRequest() {
    if (_formKey.currentState!.validate()) {
      // Logic for submitting the help request would go here
      ToastService().showSuccess('Support request submitted.', 
        message: 'We will get back to you soon!');
      Navigator.pop(context);
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
                    'Help Center',
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
                  color: appTheme.whiteA70001,
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
                        "Still need help?",
                        style: TextStyleHelper.instance.body18Bold.copyWith(
                          color: appTheme.gray900,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Describe your issue below and our team will assist you.",
                        style: TextStyleHelper.instance.body14Medium.copyWith(
                          color: appTheme.gray600,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      /// SUPPORT FORM
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Issue Category",
                              style: TextStyleHelper.instance.body14Bold.copyWith(
                                color: appTheme.gray900,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedIssueType,
                              hint: Text("Select issue type", style: TextStyleHelper.instance.body14Medium.copyWith(color: appTheme.gray400)),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: appTheme.gray50,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.h),
                                  borderSide: BorderSide(color: appTheme.gray200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.h),
                                  borderSide: BorderSide(color: appTheme.gray200),
                                ),
                              ),
                              items: _issueTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type, style: TextStyleHelper.instance.body14Medium),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedIssueType = val),
                              validator: (val) => val == null ? "Please select a category" : null,
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              "Describe your problem",
                              style: TextStyleHelper.instance.body14Bold.copyWith(
                                color: appTheme.gray900,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 5,
                              style: TextStyleHelper.instance.body14Medium,
                              decoration: InputDecoration(
                                hintText: "Tell us what happened...",
                                hintStyle: TextStyleHelper.instance.body14Medium.copyWith(color: appTheme.gray400),
                                filled: true,
                                fillColor: appTheme.gray50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.h),
                                  borderSide: BorderSide(color: appTheme.gray200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.h),
                                  borderSide: BorderSide(color: appTheme.gray200),
                                ),
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? "Description is required" : null,
                            ),
                            SizedBox(height: 32.h),
                            SizedBox(
                              width: double.infinity,
                              height: 56.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appTheme.indigoA700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.h),
                                  ),
                                ),
                                onPressed: _submitSupportRequest,
                                child: Text(
                                  "Submit Request",
                                  style: TextStyleHelper.instance.body16Bold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 40.h),
                          ],
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
}

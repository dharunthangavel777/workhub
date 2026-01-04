import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../logic/providers/auth_provider.dart';

class BecomeOwnerScreen extends StatefulWidget {
  const BecomeOwnerScreen({super.key});

  @override
  State<BecomeOwnerScreen> createState() => _BecomeOwnerScreenState();
}

class _BecomeOwnerScreenState extends State<BecomeOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _contactController = TextEditingController();
  final _infoController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _businessTypeController.dispose();
    _contactController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<AuthProvider>().submitOwnerRequest({
        'companyName': _companyNameController.text,
        'businessType': _businessTypeController.text,
        'contactDetails': _contactController.text,
        'additionalInfo': _infoController.text,
        'requestedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final status = user?.ownerRequestStatus ?? 'none';

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text("Become an Owner"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status == 'pending')
              _buildStatusCard(
                "Request Pending",
                "Your request to become a business owner is currently being reviewed by our admin team.",
                Icons.hourglass_empty,
                Colors.orange,
              )
            else if (status == 'rejected')
              _buildStatusCard(
                "Request Rejected",
                user?.rejectionReason ??
                    "Your request was not approved at this time.",
                Icons.error_outline,
                Colors.red,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upgrade your account",
                    style: TextStyle(
                      color: CustomColors.darkText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Fill out the form below to apply for a Business Owner account. Once approved, you'll gain access to hiring tools and management dashboards.",
                    style:
                        TextStyle(color: CustomColors.darkText, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _companyNameController,
                          label: "Company / Agency Name",
                          hint: "Enter your company name",
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _businessTypeController,
                          label: "Business Type",
                          hint: "e.g. Software House, Design Agency",
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _contactController,
                          label: "Contact Details",
                          hint: "Phone or Business Email",
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _infoController,
                          label: "Additional Information",
                          hint: "Tell us more about your business",
                          maxLines: 4,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CustomColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _submit,
                            child: const Text(
                              "Submit Request",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      String title, String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CustomColors.textMuted, fontSize: 16),
          ),
        ],
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
          style: const TextStyle(
            color: CustomColors.darkText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: CustomColors.darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: CustomColors.textMuted),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

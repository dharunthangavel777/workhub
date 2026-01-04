import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../data/models/milestone_model.dart';
import '../../../logic/providers/job_provider.dart';

class CreateMilestoneScreen extends StatefulWidget {
  final String projectId;
  final double projectBudget;

  const CreateMilestoneScreen({
    super.key,
    required this.projectId,
    required this.projectBudget,
  });

  @override
  State<CreateMilestoneScreen> createState() => _CreateMilestoneScreenState();
}

class _CreateMilestoneScreenState extends State<CreateMilestoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text(
          "New Milestone",
          style: TextStyle(color: CustomColors.darkText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CustomColors.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Define a clear milestone with a set budget and deadline.",
                style: TextStyle(color: CustomColors.textMuted),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _titleController,
                label: "Milestone Title",
                hint: "e.g., Design System Draft",
                validator: (v) =>
                    v?.isEmpty ?? true ? "Title is required" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                hint: "e.g., Deliver complete UI kit...",
                maxLines: 4,
                validator: (v) =>
                    v?.isEmpty ?? true ? "Description is required" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _amountController,
                label: "Amount",
                hint: "0.00",
                isNumber: true,
                prefix: "₹ ",
                validator: (v) {
                  if (v?.isEmpty ?? true) return "Amount is required";
                  final amount = double.tryParse(v!);
                  if (amount == null || amount <= 0) return "Invalid amount";
                  if (amount > widget.projectBudget) {
                    return "Exceeds project budget";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "Deadline",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _deadline = picked);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: CustomColors.primaryBlue),
                      const SizedBox(width: 12),
                      Text(
                        "${_deadline.day}/${_deadline.month}/${_deadline.year}",
                        style: const TextStyle(color: CustomColors.darkText),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Create Milestone"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isNumber = false,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: CustomColors.textMuted),
            prefixText: prefix,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final milestone = Milestone(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          projectId: widget.projectId,
          title: _titleController.text,
          description: _descriptionController.text,
          amount: double.parse(_amountController.text),
          deadline: _deadline,
        );

        await context
            .read<JobProvider>()
            .createMilestone(widget.projectId, milestone);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Milestone created successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

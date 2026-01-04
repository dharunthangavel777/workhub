import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../data/models/withdrawal_request_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/job_provider.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<JobProvider>().listenToWithdrawals(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final balance = user?.walletBalance ?? 0.0;
    _addressController.text = user?.walletAddress ?? '';

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text("Withdraw Earnings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: CustomColors.darkText,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(balance),
            const SizedBox(height: 32),
            _buildWithdrawalForm(user?.uid),
            const SizedBox(height: 32),
            const Text(
              "Recent Withdrawals",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CustomColors.darkText,
              ),
            ),
            const SizedBox(height: 16),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CustomColors.primaryBlue,
            CustomColors.primaryBlue.withValues(alpha: 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CustomColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Available Balance",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${balance.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm(String? uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Withdrawal Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _amountController,
          label: "Amount to Withdraw",
          hint: "Minimum ₹50.00",
          prefix:
              const Text("₹ ", style: TextStyle(fontWeight: FontWeight.bold)),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _addressController,
          label: "Wallet / Bank Details",
          hint: "Enter payment destination details...",
          maxLines: 3,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _handleWithdrawal(uid),
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Submit Withdrawal Request",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        const _InfoNote(
          text:
              "Withdrawal requests are typically processed within 3-5 business days. Ensure your payment details are accurate to avoid delays.",
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    final withdrawals = context.watch<JobProvider>().withdrawals;

    if (withdrawals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.history,
                size: 48, color: CustomColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              "No recent withdrawals found.",
              style: TextStyle(color: CustomColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: withdrawals.length,
      itemBuilder: (context, index) {
        final request = withdrawals[index];
        return _buildWithdrawalItem(request);
      },
    );
  }

  Widget _buildWithdrawalItem(WithdrawalRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case WithdrawalStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.timer_outlined;
        break;
      case WithdrawalStatus.processing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case WithdrawalStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case WithdrawalStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case WithdrawalStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₹${request.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "To: ${request.bankAccountName ?? 'Wallet'}",
                  style: const TextStyle(
                    color: CustomColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              request.status.name.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? prefix,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CustomColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: CustomColors.darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: CustomColors.textMuted.withValues(alpha: 0.5)),
            prefixIcon: prefix != null
                ? Padding(padding: const EdgeInsets.all(16), child: prefix)
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleWithdrawal(String? uid) async {
    final amountText = _amountController.text;
    final address = _addressController.text;

    if (amountText.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount")),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final jobProvider = context.read<JobProvider>();
    try {
      // 1. Update wallet address in profile if changed
      await jobProvider.updateUserProfile(uid!, {'walletAddress': address});

      // 2. Submit withdrawal request
      final request = WithdrawalRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: uid,
        amount: amount,
        bankAccountId: address, // Using address as ID/details for now
        bankAccountName: 'User Wallet', // Placeholder
        status: WithdrawalStatus.pending,
      );

      await jobProvider.requestWithdrawal(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal request submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

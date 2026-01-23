import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/theme/custom_colors.dart';
import 'package:work_hub/data/models/withdrawal_request_model.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/logic/providers/job_provider.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _upiIdController = TextEditingController();
  bool _isProcessing = false;
  String _paymentMethod = 'bank'; // 'bank' or 'upi'

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
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final balance = user?.walletBalance ?? 0.0;

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
        const SizedBox(height: 24),
        // Payment method selection
        const Text(
          "Payment Method",
          style: TextStyle(
            color: CustomColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodOption(
                'bank',
                'Bank Transfer',
                Icons.account_balance,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodOption(
                'upi',
                'UPI',
                Icons.qr_code_2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Conditional fields based on payment method
        if (_paymentMethod == 'bank') ..._buildBankFields(),
        if (_paymentMethod == 'upi') ..._buildUpiFields(),
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

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? CustomColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CustomColors.primaryBlue
                : Colors.black.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? CustomColors.primaryBlue
                  : CustomColors.textMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? CustomColors.primaryBlue
                    : CustomColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBankFields() {
    return [
      _buildTextField(
        controller: _accountHolderNameController,
        label: "Account Holder Name",
        hint: "Enter full name as per bank records",
      ),
      const SizedBox(height: 20),
      _buildTextField(
        controller: _accountNumberController,
        label: "Account Number",
        hint: "Enter 9-18 digit account number",
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 20),
      _buildTextField(
        controller: _ifscCodeController,
        label: "IFSC Code",
        hint: "e.g., SBIN0001234",
      ),
    ];
  }

  List<Widget> _buildUpiFields() {
    return [
      _buildTextField(
        controller: _upiIdController,
        label: "UPI ID",
        hint: "e.g., yourname@paytm",
        keyboardType: TextInputType.emailAddress,
      ),
    ];
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

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter withdrawal amount")),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimum withdrawal amount is ₹50")),
      );
      return;
    }

    // Validate based on payment method
    if (_paymentMethod == 'bank') {
      if (_accountHolderNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter account holder name")),
        );
        return;
      }

      final accountNumber = _accountNumberController.text;
      if (accountNumber.isEmpty ||
          accountNumber.length < 9 ||
          accountNumber.length > 18 ||
          !RegExp(r'^[0-9]+$').hasMatch(accountNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Please enter a valid account number (9-18 digits)")),
        );
        return;
      }

      final ifscCode = _ifscCodeController.text.toUpperCase();
      if (ifscCode.isEmpty ||
          ifscCode.length != 11 ||
          !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifscCode)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Please enter a valid IFSC code (e.g., SBIN0001234)")),
        );
        return;
      }
    } else {
      final upiId = _upiIdController.text;
      if (upiId.isEmpty || !upiId.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please enter a valid UPI ID (e.g., name@paytm)")),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    final jobProvider = context.read<JobProvider>();
    try {
      // Create withdrawal request with proper bank details
      final request = WithdrawalRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: uid!,
        amount: amount,
        bankAccountId: _paymentMethod == 'bank'
            ? _accountNumberController.text
            : _upiIdController.text,
        bankAccountName:
            _paymentMethod == 'bank' ? _accountHolderNameController.text : null,
        bankAccountNumber:
            _paymentMethod == 'bank' ? _accountNumberController.text : null,
        ifscCode: _paymentMethod == 'bank'
            ? _ifscCodeController.text.toUpperCase()
            : null,
        upiId: _paymentMethod == 'upi' ? _upiIdController.text : null,
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

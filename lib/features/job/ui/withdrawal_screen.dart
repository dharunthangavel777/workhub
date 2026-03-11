import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/features/job/logic/job_controller.dart';
import 'package:work_hub/features/wallet/models/withdrawal_request.dart';

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
                    'Withdraw Earnings',
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
                      _buildBalanceCard(balance),
                      SizedBox(height: 32.h),
                      _buildWithdrawalForm(user?.uid),
                      SizedBox(height: 32.h),
                      Text(
                        "Recent Withdrawals",
                        style: TextStyleHelper.instance.body18Bold.copyWith(
                          color: appTheme.gray_900,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildHistorySection(),
                      SizedBox(height: 40.h),
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

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CustomColors.primaryBlue,
            CustomColors.primaryBlue.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.h),
        boxShadow: [
          BoxShadow(
            color: CustomColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Available Balance",
            style: TextStyleHelper.instance.body14Medium.copyWith(color: Colors.white70),
          ),
          SizedBox(height: 8.h),
          Text(
            "₹${balance.toStringAsFixed(2)}",
            style: TextStyleHelper.instance.headline30Bold.copyWith(
              color: Colors.white,
              fontSize: 40.fSize,
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
        Text(
          "Withdrawal Details",
          style: TextStyleHelper.instance.body18Bold.copyWith(
            color: appTheme.gray_900,
          ),
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          controller: _amountController,
          label: "Amount to Withdraw",
          hint: "Minimum ₹50.00",
          prefix: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Text("₹ ", style: TextStyleHelper.instance.body14Bold),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 24.h),
        Text(
          "Payment Method",
          style: TextStyleHelper.instance.body12Medium.copyWith(
            color: appTheme.gray_500,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodOption(
                'bank',
                'Bank Transfer',
                Icons.account_balance,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildPaymentMethodOption(
                'upi',
                'UPI',
                Icons.qr_code_2,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        // Conditional fields based on payment method
        if (_paymentMethod == 'bank') ..._buildBankFields(),
        if (_paymentMethod == 'upi') ..._buildUpiFields(),
        SizedBox(height: 40.h),
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _handleWithdrawal(uid),
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.indigo_A700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.h)),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Submit Withdrawal Request",
                    style: TextStyleHelper.instance.body16Bold.copyWith(color: Colors.white),
                  ),
          ),
        ),
        SizedBox(height: 24.h),
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
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? appTheme.indigo_A700.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(
            color: isSelected
                ? appTheme.indigo_A700
                : appTheme.gray_200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? appTheme.indigo_A700
                  : appTheme.gray_400,
              size: 32.h,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyleHelper.instance.body14Medium.copyWith(
                color: isSelected
                    ? appTheme.indigo_A700
                    : appTheme.gray_500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      SizedBox(height: 20.h),
      _buildTextField(
        controller: _accountNumberController,
        label: "Account Number",
        hint: "Enter 9-18 digit account number",
        keyboardType: TextInputType.number,
      ),
      SizedBox(height: 20.h),
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
        padding: EdgeInsets.all(32.h),
        decoration: BoxDecoration(
          color: appTheme.gray_50,
          borderRadius: BorderRadius.circular(24.h),
          border: Border.all(color: appTheme.gray_100),
        ),
        child: Column(
          children: [
            Icon(Icons.history,
                size: 48.h, color: appTheme.gray_300),
            SizedBox(height: 16.h),
            Text(
              "No recent withdrawals found.",
              style: TextStyleHelper.instance.body14Medium.copyWith(color: appTheme.gray_400),
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
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24.h),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₹${request.amount.toStringAsFixed(2)}",
                  style: TextStyleHelper.instance.body16Bold,
                ),
                Text(
                  "To: ${request.bankAccountName ?? 'Wallet'}",
                  style: TextStyleHelper.instance.body12Medium.copyWith(
                    color: appTheme.gray_500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Text(
              request.status.name.toUpperCase(),
              style: TextStyleHelper.instance.body10Bold.copyWith(
                color: statusColor,
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
          style: TextStyleHelper.instance.body14Bold.copyWith(
            color: appTheme.gray_900,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyleHelper.instance.body14Medium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyleHelper.instance.body14Medium.copyWith(color: appTheme.gray_400),
            prefixIcon: prefix != null
                ? Padding(padding: EdgeInsets.only(left: 16.w, right: 8.w), child: prefix)
                : null,
            filled: true,
            fillColor: appTheme.gray_50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.h),
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
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 20.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13.fSize,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
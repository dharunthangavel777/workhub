import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/theme/custom_colors.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/data/models/project_model.dart';

class EscrowDepositScreen extends StatefulWidget {
  final ProjectModel project;

  const EscrowDepositScreen({
    super.key,
    required this.project,
  });

  @override
  State<EscrowDepositScreen> createState() => _EscrowDepositScreenState();
}

class _EscrowDepositScreenState extends State<EscrowDepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with required deposit if not already paid
    if (!widget.project.depositPaid) {
      _amountController.text =
          (widget.project.requiredDeposit ?? 0).toStringAsFixed(0);
    }

    // Pre-fill user contact info if available
    final currentUser = context.read<AuthProvider>().userModel;
    _emailController.text = currentUser?.email ?? '';
    _phoneController.text = currentUser?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().userModel;
    final project = context.watch<JobProvider>().projects.firstWhere(
          (p) => p.id == widget.project.id,
          orElse: () => widget.project,
        );

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: CustomColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Deposit to Escrow',
          style: TextStyle(
              color: CustomColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectInfo(project),
            const SizedBox(height: 24),
            _buildCurrentBalance(project),
            const SizedBox(height: 32),
            _buildContactForm(currentUser),
            const SizedBox(height: 24),
            _buildDepositForm(currentUser),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 32),
            _buildDepositButton(context, currentUser, project),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfo(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: CustomColors.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Project ID: ${widget.project.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
              fontSize: 13,
              color: CustomColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBalance(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Colors.green.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Escrow Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: CustomColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${project.escrowBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositForm(currentUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deposit Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            enabled: widget.project
                .depositPaid, // Disable editing for initial full deposit
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('₹',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              hintText: '0.00',
              helperText: !widget.project.depositPaid
                  ? "Full project amount required for initial deposit"
                  : null,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.project.depositPaid)
            Row(
              children: [
                _buildQuickAmountChip(100),
                const SizedBox(width: 8),
                _buildQuickAmountChip(250),
                const SizedBox(width: 8),
                _buildQuickAmountChip(500),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(double amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _amountController.text = amount.toStringAsFixed(0);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: CustomColors.primaryBlue,
          side: const BorderSide(color: CustomColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text('₹${amount.toInt()}'),
      ),
    );
  }

  Widget _buildContactForm(currentUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Required for payment processing',
            style: TextStyle(
              fontSize: 12,
              color: CustomColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 14,
              color: CustomColors.darkText,
            ),
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'your.email@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: CustomColors.primaryBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: const TextStyle(
              fontSize: 14,
              color: CustomColors.darkText,
            ),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '9999999999',
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '+91 ',
              counterText: '',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: CustomColors.primaryBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Escrow',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Funds deposited to escrow are held securely until you release payment for completed milestones.',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositButton(
      BuildContext context, dynamic currentUser, ProjectModel project) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isProcessing
            ? null
            : () => _initiateDeposit(context, currentUser, project),
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.payment),
        label: Text(_isProcessing ? 'Processing...' : 'Proceed to Payment'),
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _initiateDeposit(
      BuildContext context, currentUser, ProjectModel project) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (amount < 50.0) {
      _showError('Minimum deposit amount is ₹50.00');
      return;
    }

    if (currentUser == null) {
      _showError('User not authenticated');
      return;
    }

    // Validate email
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }

    // Validate phone number
    final phone = _phoneController.text.trim();
    if (phone.isEmpty ||
        phone.length != 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final jobProvider = context.read<JobProvider>();

      debugPrint(
          '💳 Initiating payment: Amount=₹$amount, Email=$email, Phone=$phone');

      // 1. Create payment order on server
      final response = await jobProvider.initiateEscrowDeposit(
        projectId: project.id,
        amount: amount,
        userId: currentUser.uid,
        userEmail: email,
        userPhone: phone,
      );

      if (response == null || response['paymentSessionId'] == null) {
        throw Exception('Failed to create payment order');
      }

      final String sessionId = response['paymentSessionId'];
      final String orderId = response['orderId'];

      // 2. Trigger Cashfree SDK / Web Gateway
      jobProvider.startPaymentFlow(
        sessionId: sessionId,
        orderId: orderId,
        onSuccess: (orderId) async {
          if (mounted) {
            await _handlePaymentSuccess(
                amount, sessionId, orderId, currentUser.uid, project);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isProcessing = false);
            _showError('Payment failed: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Error initiating payment: $e');
      }
    }
  }

  Future<void> _handlePaymentSuccess(
    double amount,
    String sessionId,
    String orderId,
    String userId,
    ProjectModel project,
  ) async {
    try {
      final jobProvider = context.read<JobProvider>();

      // 3. Verify payment status and record in Firestore
      final success = await jobProvider.confirmEscrowDeposit(
        projectId: project.id,
        amount: amount,
        paymentSessionId: sessionId,
        userId: userId,
        orderId: orderId,
      );

      if (success && mounted) {
        _showSuccessDialog(amount);
      } else if (mounted) {
        _showError('Payment verification failed. Please contact support.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error confirming payment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: CustomColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Deposit Successful'),
          ],
        ),
        content: Text(
          '₹${amount.toStringAsFixed(2)} has been successfully deposited to the project escrow.',
          style: const TextStyle(color: CustomColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

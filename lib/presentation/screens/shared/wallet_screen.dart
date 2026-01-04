import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../data/models/withdrawal_request_model.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/job_provider.dart';

import '../worker/withdrawal_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
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
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final double availableBalance = user?.walletBalance ?? 0.0;

    final withdrawals = context.watch<JobProvider>().withdrawals;
    final isLoading = context.watch<JobProvider>().isLoading;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text(
          "Wallet",
          style: TextStyle(color: CustomColors.darkText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CustomColors.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(availableBalance),
            const SizedBox(height: 32),
            const Text(
              "Recent Transactions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CustomColors.darkText,
              ),
            ),
            const SizedBox(height: 16),
            isLoading && withdrawals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : withdrawals.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: withdrawals.length,
                        itemBuilder: (context, index) {
                          return _buildWithdrawalItem(withdrawals[index]);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CustomColors.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CustomColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Balance",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${balance.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WithdrawalScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: CustomColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Request Withdrawal",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.moneyBillTransfer,
              size: 48,
              color: CustomColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              "No transactions yet",
              style: TextStyle(color: CustomColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalItem(WithdrawalRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case WithdrawalStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case WithdrawalStatus.processing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case WithdrawalStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case WithdrawalStatus.failed:
      case WithdrawalStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          "Withdrawal",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText,
          ),
        ),
        subtitle: Text(
          _formatDate(request.requestedAt),
          style: const TextStyle(color: CustomColors.textMuted),
        ),
        trailing: Text(
          "-₹${request.amount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

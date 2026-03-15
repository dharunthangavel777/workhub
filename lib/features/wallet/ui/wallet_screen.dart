import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qwok/core/theme/custom_colors.dart';
import 'package:qwok/core/shared_widgets/predictive_shimmer.dart';

import 'package:qwok/features/auth/logic/auth_controller.dart';
import 'package:qwok/features/job/logic/job_controller.dart';
import 'package:qwok/features/job/ui/withdrawal_screen.dart';
import 'package:qwok/features/wallet/models/withdrawal_request.dart';
import 'package:qwok/features/wallet/models/transaction.dart';

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
        context.read<JobProvider>().listenToTransactions(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final double availableBalance = user?.walletBalance ?? 0.0;

    final withdrawals = context.watch<JobProvider>().withdrawals;
    final transactions = context.watch<JobProvider>().transactions;
    final isLoading = context.watch<JobProvider>().isLoading;

    // Combine and sort by date
    final List<dynamic> allActivities = [...withdrawals, ...transactions];
    allActivities.sort((a, b) {
      final dateA = a is WithdrawalRequest ? a.requestedAt : (a as Transaction).createdAt;
      final dateB = b is WithdrawalRequest ? b.requestedAt : (b as Transaction).createdAt;
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Wallet",
          style: TextStyle(color: CustomColors.darkText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CustomColors.darkText),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = context.read<AuthProvider>().userModel;
          if (user != null) {
            await context.read<JobProvider>().fetchTransactions(user.uid);
            // Withdrawals are streamed, but we can refresh other things if needed
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(availableBalance),
            const SizedBox(height: 32),
            const Text(
              "Recent Activity",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CustomColors.darkText,
              ),
            ),
            const SizedBox(height: 16),
            isLoading && allActivities.isEmpty
                ? Column(
                    children: List.generate(
                      3,
                      (index) => _buildShimmerItem(),
                    ),
                  )
                : allActivities.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allActivities.length,
                        itemBuilder: (context, index) {
                          final activity = allActivities[index];
                          if (activity is WithdrawalRequest) {
                            return _buildWithdrawalItem(activity);
                          } else {
                            return _buildTransactionItem(activity as Transaction);
                          }
                        },
                      ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: const Row(
        children: [
          PredictiveShimmer(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(20))),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PredictiveShimmer(width: 100, height: 14),
                SizedBox(height: 8),
                PredictiveShimmer(width: 80, height: 10),
              ],
            ),
          ),
          PredictiveShimmer(width: 60, height: 16),
        ],
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

  Widget _buildTransactionItem(Transaction transaction) {
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
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
        ),
        title: Text(
          transaction.description.isEmpty ? "Payment Received" : transaction.description,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: CustomColors.darkText,
          ),
        ),
        subtitle: Text(
          _formatDate(transaction.createdAt),
          style: const TextStyle(color: CustomColors.textMuted),
        ),
        trailing: Text(
          "+₹${transaction.amount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 16,
          ),
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
        title: const Text(
          "Withdrawal",
          style: TextStyle(
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    }

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }
}




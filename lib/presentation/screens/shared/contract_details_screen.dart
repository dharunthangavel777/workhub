import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../data/models/contract_terms_model.dart';
import '../../../logic/providers/job_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class ContractDetailsScreen extends StatefulWidget {
  final String contractId;

  const ContractDetailsScreen({
    super.key,
    required this.contractId,
  });

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchContract(widget.contractId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final authProvider = context.watch<AuthProvider>();
    final contract = jobProvider.currentContract;
    final currentUser = authProvider.userModel;

    if (jobProvider.isLoading || contract == null || currentUser == null) {
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
            'Contract Details',
            style: TextStyle(
                color: CustomColors.darkText, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');

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
          'Contract Details',
          style: TextStyle(
              color: CustomColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(contract),
            const SizedBox(height: 24),
            _buildContractInfo(contract, dateFormat),
            const SizedBox(height: 20),
            _buildFinancialDetails(contract),
            const SizedBox(height: 20),
            _buildTimeline(contract, dateFormat),
            const SizedBox(height: 20),
            _buildSignatures(contract, dateTimeFormat),
            const SizedBox(height: 32),
            _buildActionButtons(context, contract, currentUser.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ContractTerms contract,
    String userId,
  ) {
    final jobProvider = context.read<JobProvider>();
    // Determine project to get owner/worker IDs
    final project = jobProvider.projects
        .where((p) => p.id == contract.projectId)
        .firstOrNull;

    if (project == null) {
      // If project is not in the list, we can't reliably determine role for signing
      return const SizedBox.shrink();
    }

    final isOwner = userId == project.ownerId;
    final isWorker = userId == project.workerId;
    final canSign = (isOwner && !contract.ownerAccepted) ||
        (isWorker && !contract.workerAccepted);

    if (!canSign) return const SizedBox.shrink();

    final role = isOwner ? 'owner' : 'worker';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () =>
                _acceptContract(context, contract.id, userId, role),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept Contract & Start Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "By clicking accept, you agree to the terms and conditions outlined in this contract.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: CustomColors.textMuted,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptContract(
    BuildContext context,
    String contractId,
    String userId,
    String role,
  ) async {
    final jobProvider = context.read<JobProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await jobProvider.acceptContract(contractId, userId, role);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contract accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting contract: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHeader(ContractTerms contract) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: contract.isFullyAccepted
              ? [Colors.green.shade100, Colors.green.shade50]
              : [Colors.grey.shade100, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contract.isFullyAccepted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
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
              contract.isFullyAccepted ? Icons.verified : Icons.description,
              color: contract.isFullyAccepted ? Colors.green : Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.isFullyAccepted ? 'Active Contract' : 'Contract',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: contract.isFullyAccepted
                        ? Colors.green.shade900
                        : CustomColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${contract.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: CustomColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractInfo(ContractTerms contract, DateFormat dateFormat) {
    return _buildCard(
      title: 'Contract Information',
      child: Column(
        children: [
          _buildInfoRow(
              'Contract ID', contract.id.substring(0, 12).toUpperCase()),
          _buildInfoRow(
              'Project ID', contract.projectId.substring(0, 12).toUpperCase()),
          _buildInfoRow('Payment Type', contract.paymentType.toUpperCase()),
          _buildInfoRow('Created', dateFormat.format(contract.createdAt)),
        ],
      ),
    );
  }

  Widget _buildFinancialDetails(ContractTerms contract) {
    final platformFeeAmount =
        contract.agreedBudget * contract.platformFee / 100;
    final totalAmount = contract.agreedBudget + platformFeeAmount;

    return _buildCard(
      title: 'Financial Details',
      child: Column(
        children: [
          _buildFinancialRow(
              'Worker Budget', '₹${contract.agreedBudget.toStringAsFixed(2)}'),
          _buildFinancialRow(
            'Platform Fee (${contract.platformFee.toStringAsFixed(1)}%)',
            '+₹${platformFeeAmount.toStringAsFixed(2)}',
            isNegative: false, // Changed from negative
          ),
          const Divider(height: 24),
          _buildFinancialRow(
            'Total Project Cost',
            '₹${totalAmount.toStringAsFixed(2)}',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ContractTerms contract, DateFormat dateFormat) {
    final duration =
        contract.expectedCompletion.difference(contract.startDate).inDays;

    return _buildCard(
      title: 'Project Timeline',
      child: Column(
        children: [
          _buildInfoRow('Start Date', dateFormat.format(contract.startDate)),
          _buildInfoRow('Expected Completion',
              dateFormat.format(contract.expectedCompletion)),
          _buildInfoRow('Duration', '$duration days'),
        ],
      ),
    );
  }

  Widget _buildSignatures(ContractTerms contract, DateFormat dateTimeFormat) {
    return _buildCard(
      title: 'Signatures',
      child: Column(
        children: [
          _buildSignatureRow(
            'Owner',
            contract.ownerAccepted,
            contract.ownerAcceptedAt != null
                ? dateTimeFormat.format(contract.ownerAcceptedAt!)
                : null,
          ),
          const SizedBox(height: 12),
          _buildSignatureRow(
            'Worker',
            contract.workerAccepted,
            contract.workerAcceptedAt != null
                ? dateTimeFormat.format(contract.workerAcceptedAt!)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: CustomColors.textMuted, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: CustomColors.darkText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value, {
    bool isNegative = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isHighlight ? CustomColors.darkText : CustomColors.textMuted,
              fontSize: isHighlight ? 15 : 14,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isNegative
                  ? Colors.red
                  : (isHighlight
                      ? CustomColors.primaryBlue
                      : CustomColors.darkText),
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureRow(String party, bool signed, String? signedAt) {
    return Row(
      children: [
        Icon(
          signed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: signed ? Colors.green : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                party,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CustomColors.darkText,
                  fontSize: 15,
                ),
              ),
              if (signedAt != null)
                Text(
                  'Signed on $signedAt',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CustomColors.textMuted,
                  ),
                )
              else
                const Text(
                  'Not signed yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: CustomColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/custom_colors.dart';
import '../../data/models/project_model.dart';
import '../../logic/providers/job_provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../screens/shared/contract_details_screen.dart';
import '../screens/owner/escrow_deposit_screen.dart';
import '../screens/shared/milestone_list_screen.dart';

class ProjectSetupStepper extends StatefulWidget {
  final ProjectModel project;

  const ProjectSetupStepper({super.key, required this.project});

  @override
  State<ProjectSetupStepper> createState() => _ProjectSetupStepperState();
}

class _ProjectSetupStepperState extends State<ProjectSetupStepper> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchContractByProjectId(widget.project.id);
      context.read<JobProvider>().listenToMilestones(widget.project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.userModel;
    final isOwner = currentUser?.uid == widget.project.ownerId;
    final contract = jobProvider.currentContract;
    final milestones = jobProvider.milestones;

    bool contractSigned = contract?.isFullyAccepted ?? false;
    bool depositPaid = widget.project.depositPaid;
    bool milestonesSet = milestones.isNotEmpty;
    bool milestonesAgreed =
        milestonesSet && milestones.every((m) => m.workerAgreed);

    // Determine current step
    if (!contractSigned) {
      _currentStep = 0;
    } else if (!depositPaid) {
      _currentStep = 1;
    } else {
      _currentStep = 2;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Project Setup",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CustomColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Complete these steps to unlock the project dashboard.",
            style: TextStyle(color: CustomColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildStep(
            index: 0,
            title: "Contract Agreement",
            description: "Review and sign the project contract.",
            isCompleted: contractSigned,
            isActive: _currentStep == 0,
            onTap: () {
              if (contract != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ContractDetailsScreen(contractId: contract.id),
                  ),
                );
              }
            },
          ),
          _buildDivider(),
          _buildStep(
            index: 1,
            title: "Security Deposit",
            description:
                "Owner must deposit ₹${widget.project.requiredDeposit ?? 0} to initiate.",
            isCompleted: depositPaid,
            isActive: _currentStep == 1,
            onTap: isOwner && contractSigned
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EscrowDepositScreen(project: widget.project),
                      ),
                    );
                  }
                : null,
          ),
          _buildDivider(),
          _buildStep(
            index: 2,
            title: "Milestone Planning",
            description: milestonesSet
                ? (milestonesAgreed
                    ? "All milestones agreed."
                    : "Waiting for worker agreement.")
                : "Owner must create project milestones.",
            isCompleted: milestonesAgreed,
            isActive: _currentStep == 2,
            onTap: depositPaid
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MilestoneListScreen(project: widget.project),
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: 32),
          if (contractSigned && depositPaid && milestonesAgreed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  jobProvider
                      .updateProject(widget.project.id, {'status': 'active'});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Unlock Dashboard"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int index,
    required String title,
    required String description,
    required bool isCompleted,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : (isActive
                        ? CustomColors.primaryBlue
                        : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive || isCompleted
                          ? CustomColors.darkText
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive || isCompleted
                          ? CustomColors.textMuted
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null && !isCompleted && isActive)
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: CustomColors.primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 15),
      height: 20,
      width: 2,
      color: Colors.grey.shade200,
    );
  }
}

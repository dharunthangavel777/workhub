import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qwok/core/theme/custom_colors.dart';
import 'package:qwok/core/services/toast_service.dart';
import 'package:qwok/features/freelance/models/project.dart';
import 'package:qwok/features/job/logic/job_controller.dart';
import 'package:qwok/features/auth/logic/auth_controller.dart';
import 'package:qwok/features/auth/models/user.dart';
import '../../common/contract/ui/contract_details_screen.dart';
import '../ui/milestone_list_screen.dart';

class ProjectSetupStepper extends StatefulWidget {
  final Project project;

  const ProjectSetupStepper({super.key, required this.project});

  @override
  State<ProjectSetupStepper> createState() => _ProjectSetupStepperState();
}

class _ProjectSetupStepperState extends State<ProjectSetupStepper> {
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
    return Selector2<AuthProvider, JobProvider, _StepperData>(
      selector: (_, auth, job) => _StepperData(
        currentUser: auth.userModel,
        contract: job.currentContract,
        milestones: job.milestones,
        projects: job.projects,
      ),
      builder: (context, data, _) {
        final milestones = data.milestones;
        final contract = data.contract;
        final isOwner = data.currentUser?.uid == widget.project.ownerId;

        bool contractSigned = contract?.isFullyAccepted ?? false;
        bool depositPaid = widget.project.depositPaid;
        bool milestonesSet = milestones.isNotEmpty;
        bool milestonesAgreed =
            milestonesSet && milestones.every((m) => m.workerAgreed);

        // Determine current step
        int currentStep;
        if (!contractSigned) {
          currentStep = 0;
        } else if (!depositPaid) {
          currentStep = 1;
        } else {
          currentStep = 2;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
              const Text(
                "Complete these steps to unlock the project dashboard.",
                style: TextStyle(color: CustomColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),
              RepaintBoundary(
                child: _buildStep(
                  index: 0,
                  title: "Contract Agreement",
                  description: "Review and sign the project contract.",
                  isCompleted: contractSigned,
                  isActive: currentStep == 0,
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
              ),
              _buildDivider(),
              RepaintBoundary(
                child: _buildStep(
                  index: 1,
                  title: "Security Deposit",
                  description:
                      "Owner must deposit ₹${widget.project.requiredDeposit ?? 0} to initiate.",
                  isCompleted: depositPaid,
                  isActive: currentStep == 1,
                  onTap: isOwner && contractSigned && !depositPaid
                      ? () async {
                          try {
                            final depositAmount =
                                widget.project.requiredDeposit ??
                                    widget.project.budget ??
                                    0.0;

                            if (depositAmount <= 0) {
                              ToastService().showError("Invalid deposit amount.");
                              return;
                            }

                            await context.read<JobProvider>().processDeposit(
                                  widget.project.id,
                                  depositAmount,
                                );

                            ToastService().showSuccess("Deposit successful!", 
                              message: "Project funds secured.");
                          } catch (e) {
                            ToastService().showError("Deposit failed: $e");
                          }
                        }
                      : null,
                ),
              ),
              _buildDivider(),
              RepaintBoundary(
                child: _buildStep(
                  index: 2,
                  title: "Milestone Planning",
                  description: milestonesSet
                      ? (milestonesAgreed
                          ? "All milestones agreed."
                          : "Waiting for worker agreement.")
                      : "Owner must create project milestones.",
                  isCompleted: milestonesAgreed,
                  isActive: currentStep == 2,
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
              ),
              const SizedBox(height: 32),
              if (contractSigned && depositPaid && milestonesAgreed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<JobProvider>().updateProject(
                          widget.project.id, {'status': 'active'});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.primaryBlue,
                      foregroundColor: Colors.white,
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
      },
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

class _StepperData {
  final UserModel? currentUser;
  final dynamic contract;
  final List<dynamic> milestones;
  final List<dynamic> projects;
  _StepperData({
    required this.currentUser,
    required this.contract,
    required this.milestones,
    required this.projects,
  });
}




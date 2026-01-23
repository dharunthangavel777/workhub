import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:work_hub/data/models/milestone_model.dart';
import 'package:work_hub/data/models/project_model.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import 'package:work_hub/theme/theme_helper.dart';
import 'package:work_hub/utils/size_utils.dart';

class MilestoneListSection extends StatelessWidget {
  final ProjectModel project;
  const MilestoneListSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final milestones = context.watch<JobProvider>().milestones;

    if (milestones.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.h),
        width: double.infinity,
        decoration: BoxDecoration(
            color: appTheme.gray_50, borderRadius: BorderRadius.circular(24.h)),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, color: appTheme.gray_300, size: 32.h),
            SizedBox(height: 12.h),
            Text("No milestones created yet",
                style: TextStyleHelper.instance.body14Medium
                    .copyWith(color: appTheme.gray_500)),
          ],
        ),
      );
    }

    return Column(
      children: milestones
          .map((milestone) => _buildMilestoneCard(context, milestone))
          .toList(),
    );
  }

  Widget _buildMilestoneCard(BuildContext context, Milestone milestone) {
    final isCompleted = milestone.status == MilestoneStatus.approved;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.h),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.1)
                  : appTheme.indigo_A700.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.flag,
              color: isCompleted ? Colors.green : appTheme.indigo_A700,
              size: 20.h,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milestone.title,
                    style: TextStyleHelper.instance.body14Bold),
                SizedBox(height: 4.h),
                Text(
                  "₹${milestone.amount.toStringAsFixed(0)} • ${intl.DateFormat('MMM dd').format(milestone.deadline)}",
                  style: TextStyleHelper.instance.body12Medium
                      .copyWith(color: appTheme.gray_500),
                ),
              ],
            ),
          ),
          _buildStatusChip(milestone.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MilestoneStatus status) {
    Color color = appTheme.gray_500;
    String label = "Pending";

    switch (status) {
      case MilestoneStatus.approved:
        color = Colors.green;
        label = "Approved";
        break;
      case MilestoneStatus.submitted:
        color = Colors.orange;
        label = "Review";
        break;
      case MilestoneStatus.pending:
        color = Colors.blue;
        label = "Active";
        break;
      case MilestoneStatus.revisionRequested:
        color = Colors.red;
        label = "Revision";
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyleHelper.instance.body10Bold.copyWith(color: color),
      ),
    );
  }
}

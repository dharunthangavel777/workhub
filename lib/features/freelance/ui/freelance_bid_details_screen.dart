import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qwok/core/config/app_export.dart';
import 'package:qwok/features/job/domain/models/job.dart';
import 'package:qwok/features/auth/logic/auth_controller.dart';

class FreelanceBidDetailsScreen extends StatelessWidget {
  final Job post;
  final String? applicationStatus;

  const FreelanceBidDetailsScreen({
    super.key,
    required this.post,
    this.applicationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().userModel?.uid;
    final appData = post.applicants?[userId];
    final status = applicationStatus ?? appData?['status'] as String?;
    
    // Bid specific data
    final bidAmount = appData?['bidAmount'] ?? 0.0;
    final proposal = appData?['proposal'] as String? ?? "No proposal content provided.";
    final deliveryTime = appData?['deliveryTime'] as String? ?? "Not specified";
    final milestones = appData?['suggestedMilestones'] as List? ?? [];

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
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Bid Details',
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
                  color: appTheme.whiteA70001,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBidStatusCard(status),
                      SizedBox(height: 16.h),
                      _buildProposalSummaryCard(bidAmount, deliveryTime, post),
                      SizedBox(height: 24.h),
                      _buildSuccessInsights(),
                      SizedBox(height: 24.h),
                      _buildProposalTextSection(proposal),
                      SizedBox(height: 24.h),
                      if (milestones.isNotEmpty) ...[
                        _buildMilestonesSection(milestones),
                        SizedBox(height: 24.h),
                      ],
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

  Widget _buildSuccessInsights() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CustomColors.primaryBlue.withValues(alpha: 0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: CustomColors.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: CustomColors.primaryBlue, size: 20.h),
              SizedBox(width: 8.w),
              Text(
                "Bid Insights",
                style: TextStyleHelper.instance.body14Bold.copyWith(color: CustomColors.primaryBlue),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "Your bid is competitive! You are among the top 20% of bidders for this project based on your profile and proposed timeline.",
            style: TextStyleHelper.instance.body12Medium.copyWith(color: appTheme.gray700),
          ),
        ],
      ),
    );
  }

  Widget _buildBidStatusCard(String? status) {
    final lowerStatus = status?.toLowerCase() ?? 'pending';
    int currentStep = 0;
    if (lowerStatus == 'applied' || lowerStatus == 'pending') currentStep = 0;
    if (lowerStatus == 'reviewing' || lowerStatus == 'shortlisted') currentStep = 1;
    if (lowerStatus == 'approved' || lowerStatus == 'hired' || lowerStatus == 'rejected') currentStep = 2;

    final List<String> steps = [
      "Bid Submitted",
      lowerStatus == 'shortlisted' ? "Shortlisted" : "Reviewing",
      lowerStatus == 'rejected' ? "Rejected" : (lowerStatus == 'hired' || lowerStatus == 'approved' ? "Hired" : "Verdict")
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bid Status",
                style: TextStyleHelper.instance.body18Bold,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(lowerStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lowerStatus.toUpperCase(),
                  style: TextStyleHelper.instance.body12Bold.copyWith(
                    color: _getStatusColor(lowerStatus),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index % 2 != 0) {
                final stepIndex = index ~/ 2;
                final isCompleted = currentStep > stepIndex;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 14.h),
                    height: 2.h,
                    color: isCompleted ? CustomColors.primaryBlue : appTheme.gray300,
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isActive = stepIndex == currentStep;
              final isCompleted = currentStep > stepIndex;
              final isRejected = lowerStatus == 'rejected' && stepIndex == 2;
              final isHired = (lowerStatus == 'hired' || lowerStatus == 'approved') && stepIndex == 2;

              Color circleColor = appTheme.gray300;
              if (isActive || isCompleted) circleColor = CustomColors.primaryBlue;
              if (isRejected) circleColor = Colors.red;
              if (isHired) circleColor = Colors.green;

              return Column(
                children: [
                  Container(
                    width: 30.h,
                    height: 30.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted || isActive || isRejected || isHired ? circleColor : Colors.white,
                      border: Border.all(
                        color: isCompleted || isActive || isRejected || isHired ? circleColor : appTheme.gray400,
                        width: 2,
                      ),
                    ),
                    child: isCompleted || isRejected || isHired
                        ? Icon(
                            isRejected ? Icons.close : Icons.check,
                            color: Colors.white,
                            size: 16.h,
                          )
                        : (isActive
                            ? Container(
                                margin: EdgeInsets.all(4.h),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: 75.w,
                    child: Text(
                      steps[stepIndex],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10.fSize,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? appTheme.black900 : appTheme.gray500,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hired':
      case 'approved':
        return Colors.green;
      case 'shortlisted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'reviewing':
        return Colors.orange;
      default:
        return appTheme.indigoA700;
    }
  }

  Widget _buildProposalSummaryCard(dynamic bidAmount, String deliveryTime, Job post) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Project Overview",
            style: TextStyleHelper.instance.body18Bold,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              CustomImageView(
                imagePath: post.companyLogo ?? ImageConstant.imgImage4,
                height: 48.h,
                width: 48.h,
                radius: BorderRadius.circular(8.h),
                fit: BoxFit.cover,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: TextStyleHelper.instance.body16Bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      post.companyName ?? "Private Client",
                      style: TextStyleHelper.instance.body14Medium.copyWith(
                        color: appTheme.indigoA700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const Divider(),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildSummaryItem(Icons.payments_outlined, "Proposed Bid", "₹${bidAmount.toString()}"),
              const Spacer(),
              _buildSummaryItem(Icons.timer_outlined, "Timeline", deliveryTime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.h),
          decoration: BoxDecoration(
            color: CustomColors.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: CustomColors.primaryBlue, size: 20.h),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyleHelper.instance.body12Medium.copyWith(color: appTheme.gray500)),
            Text(value, style: TextStyleHelper.instance.body14Bold),
          ],
        ),
      ],
    );
  }

  Widget _buildProposalTextSection(String proposal) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Proposal",
            style: TextStyleHelper.instance.body18Bold,
          ),
          SizedBox(height: 12.h),
          Text(
            proposal,
            style: TextStyleHelper.instance.body14Medium.copyWith(
              color: appTheme.gray700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection(List milestones) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
            child: Text(
              "Proposed Milestones",
              style: TextStyleHelper.instance.body18Bold,
            ),
          ),
          ...milestones.asMap().entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.h),
                border: Border.all(color: appTheme.gray200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.h,
                    height: 32.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: CustomColors.primaryBlue,
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone['title'] ?? "Milestone",
                          style: TextStyleHelper.instance.body14Bold,
                        ),
                        Text(
                          milestone['description'] ?? "",
                          style: TextStyleHelper.instance.body12Medium.copyWith(color: appTheme.gray500),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${milestone['amount']}",
                    style: TextStyleHelper.instance.body14Bold.copyWith(color: CustomColors.primaryBlue),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

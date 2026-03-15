import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qwok/core/config/app_export.dart';
import 'package:qwok/features/job/domain/models/job.dart';
import 'package:qwok/features/auth/logic/auth_controller.dart';

import 'package:intl/intl.dart';

class JobApplicationDetailsScreen extends StatelessWidget {
  final Job post;
  final String? applicationStatus;

  const JobApplicationDetailsScreen({
    super.key,
    required this.post,
    this.applicationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().userModel?.uid;
    final appData = post.applicants?[userId];
    final status = applicationStatus ?? appData?['status'] as String?;
    final rejectionDescription = appData?['rejectionDescription'] as String?;
    final shortlistGreeting = appData?['shortlistGreeting'] as String?;

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
                    'Application Details',
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
                      _buildApplicationStatusCard(status),
                      SizedBox(height: 16.h),
                      if (status?.toLowerCase() == 'shortlisted' &&
                          shortlistGreeting != null) ...[
                        _buildGreetingLetter(shortlistGreeting),
                        SizedBox(height: 24.h),
                      ],
                      _buildJobSummaryCard(status, rejectionDescription),
                      SizedBox(height: 24.h),
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

  Widget _buildApplicationStatusCard(String? status) {
    // Determine current step based on status
    final lowerStatus = status?.toLowerCase() ?? 'pending';
    int currentStep = 0;
    if (lowerStatus == 'applied' || lowerStatus == 'pending') currentStep = 0;
    if (lowerStatus == 'reviewing' ||
        lowerStatus == 'interviewing' ||
        lowerStatus == 'under review' ||
        lowerStatus == 'waitlisted') {
      currentStep = 1;
    }
    if (lowerStatus == 'offered' ||
        lowerStatus == 'hired' ||
        lowerStatus == 'approved' ||
        lowerStatus == 'shortlisted' ||
        lowerStatus == 'rejected') {
      currentStep = 2;
    }

    final List<String> steps = [
      "Application Sent",
      lowerStatus == 'waitlisted' ? "Waitlisted" : "Under Review",
      lowerStatus == 'rejected'
          ? "Rejected"
          : (lowerStatus == 'shortlisted' ? "Shortlisted" : "Decision Reached")
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
            "Application Status",
            style: TextStyleHelper.instance.headline22Bold,
          ),
          SizedBox(height: 8.h),
          Text(
            "Status: ${lowerStatus[0].toUpperCase()}${lowerStatus.substring(1)}",
            style: TextStyleHelper.instance.body14Medium.copyWith(
              color: lowerStatus == 'rejected'
                  ? Colors.red
                  : (lowerStatus == 'shortlisted'
                      ? Colors.green
                      : (lowerStatus == 'waitlisted'
                          ? Colors.orange
                          : appTheme.indigoA700)),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index % 2 != 0) {
                // Return divider
                final stepIndex = index ~/ 2;
                final isCompleted = currentStep > stepIndex;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 14.h),
                    height: 2.h,
                    color:
                        isCompleted ? appTheme.indigoA700 : appTheme.gray300,
                  ),
                );
              }

              // Return step circle
              final stepIndex = index ~/ 2;
              final isActive = stepIndex == currentStep;
              final isCompleted = currentStep > stepIndex;
              final isRejected = lowerStatus == 'rejected' && stepIndex == 2;
              final isShortlisted =
                  lowerStatus == 'shortlisted' && stepIndex == 2;

              Color circleColor = appTheme.gray300;
              if (isActive || isCompleted) circleColor = appTheme.indigoA700;
              if (isRejected) circleColor = Colors.red;
              if (isShortlisted) circleColor = Colors.green;

              return Column(
                children: [
                  Container(
                    width: 30.h,
                    height: 30.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isCompleted || isActive || isRejected || isShortlisted
                              ? circleColor
                              : Colors.white,
                      border: Border.all(
                        color: isCompleted ||
                                isActive ||
                                isRejected ||
                                isShortlisted
                            ? circleColor
                            : appTheme.gray400,
                        width: 2,
                      ),
                    ),
                    child: isCompleted || isRejected || isShortlisted
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
                    width: 70.w,
                    child: Text(
                      steps[stepIndex],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10.fSize,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color:
                            isActive ? appTheme.black900 : appTheme.gray500,
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

  Widget _buildGreetingLetter(String content) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appTheme.indigoA700.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: appTheme.indigoA700.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.description_outlined,
              color: appTheme.indigoA700, size: 32),
          const SizedBox(height: 20),
          const Text(
            "Shortlist Invitation",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 1,
            width: 60,
            color: appTheme.indigoA700.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            post.companyName ?? "The Team",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: appTheme.indigoA700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSummaryCard(String? status, String? rejectionDescription) {
    final companyName = post.companyName ??
        (post.postType == 'job' ? "Unknown Company" : "Freelance Project");
    final appliedDate = post.appliedAt != null
        ? DateFormat('MMM dd, yyyy').format(post.appliedAt!)
        : 'Recently';

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
            "About the Role",
            style: TextStyleHelper.instance.headline22Bold,
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomImageView(
                imagePath: post.companyLogo ?? ImageConstant.imgImage4,
                height: 50.h,
                width: 50.h,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      companyName,
                      style: TextStyleHelper.instance.body14Medium.copyWith(
                        color: appTheme.indigoA700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      post.location,
                      style: TextStyleHelper.instance.body14Medium.copyWith(
                        color: appTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: appTheme.gray300),
          SizedBox(height: 16.h),
          _buildDetailRow(
              Icons.calendar_today_outlined, "Applied On", appliedDate),
          SizedBox(height: 12.h),
          _buildDetailRow(Icons.work_outline, "Job Type", post.type),
          SizedBox(height: 12.h),
          _buildDetailRow(
              Icons.laptop_chromebook_outlined, "Work Mode", post.workMode),
          if (status?.toLowerCase() == 'rejected' &&
              rejectionDescription != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Feedback from Owner",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rejectionDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: appTheme.gray500, size: 20.h),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyleHelper.instance.body14Medium.copyWith(
            color: appTheme.gray500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyleHelper.instance.body14Bold,
        ),
      ],
    );
  }
}

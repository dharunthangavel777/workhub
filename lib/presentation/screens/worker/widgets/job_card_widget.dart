import 'package:flutter/material.dart';
import '../../../../core/app_export.dart';
import '../../../widgets/shared/custom_image_view.dart';
import '../../../../data/models/job_post_model.dart';
import '../../../../data/models/project_post_model.dart';

class JobCardWidget extends StatelessWidget {
  final String? title;
  final String? company;
  final String? rating;
  final String? location;
  final String? workMode;
  final String? timeAgo;
  final String? companyLogo;
  final int? totalVacancies;
  final int? totalApplications;
  final VoidCallback? onTap;

  JobCardWidget({
    Key? key,
    this.title,
    this.company,
    this.rating,
    this.location,
    this.workMode,
    this.timeAgo,
    this.companyLogo,
    this.totalVacancies,
    this.totalApplications,
    this.onTap,
  }) : super(key: key);

  factory JobCardWidget.fromJobPost(JobPostModel job, {VoidCallback? onTap}) {
    return JobCardWidget(
      title: job.jobTitle,
      company: job.companyName,
      rating: "4.3",
      location: job.jobLocation,
      workMode: job.workMode,
      timeAgo: _calculateTimeAgo(job.createdAt),
      companyLogo: job.companyLogo,
      totalVacancies: job.openings,
      totalApplications: job.applicationsCount,
      onTap: onTap,
    );
  }

  factory JobCardWidget.fromProjectPost(ProjectPostModel project,
      {VoidCallback? onTap}) {
    return JobCardWidget(
      title: project.projectTitle,
      company: project.companyName ?? "Freelance Project",
      rating: "4.5",
      location: project.projectLocation,
      workMode: project.workMode,
      timeAgo: _calculateTimeAgo(project.createdAt),
      companyLogo: project.companyLogo,
      totalVacancies: project.maxApplications ?? 1,
      totalApplications: project.applicationsCount,
      onTap: onTap,
    );
  }

  static String _calculateTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    return '${duration.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(22.h),
        decoration: BoxDecoration(
          color: appTheme.gray_100,
          borderRadius: BorderRadius.circular(14.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.color3F0000.withOpacity(0.05),
              blurRadius: 4.h,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? "",
                        style: TextStyleHelper.instance.title20BlackDMSans,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              company ?? "",
                              style: TextStyleHelper
                                  .instance.body14MediumPoppins
                                  .copyWith(color: appTheme.indigo_A700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 1.h,
                            height: 14.h,
                            margin: EdgeInsets.symmetric(horizontal: 8.h),
                            color: appTheme.black_900.withOpacity(0.2),
                          ),
                          Text(
                            rating ?? "4.3",
                            style:
                                TextStyleHelper.instance.body12SemiBoldPoppins,
                          ),
                          SizedBox(width: 4.h),
                          CustomImageView(
                            imagePath:
                                ImageConstant.imgMaterialSymbolsStarRounded,
                            width: 12.h,
                            height: 12.h,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.h),
                Container(
                  width: 48.h,
                  height: 48.h,
                  padding: EdgeInsets.all(4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                  child: CustomImageView(
                    imagePath: companyLogo ?? "",
                    width: 40.h,
                    height: 40.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                if (totalVacancies != null) ...[
                  CustomImageView(
                    imagePath: ImageConstant.imgMaterialSymbolsPersonRounded,
                    width: 16.h,
                    height: 16.h,
                    color: appTheme.indigo_A700,
                  ),
                  SizedBox(width: 4.h),
                  Text(
                    "$totalVacancies Vacancies",
                    style:
                        TextStyleHelper.instance.body12SemiBoldPoppins.copyWith(
                      color: appTheme.black_900.withOpacity(0.6),
                      fontSize: 13.fSize,
                    ),
                  ),
                  SizedBox(width: 16.h),
                ],
                if (totalApplications != null) ...[
                  CustomImageView(
                    imagePath: ImageConstant.imgMaterialSymbolsGroupRounded,
                    width: 16.h,
                    height: 16.h,
                    color: appTheme.indigo_A700,
                  ),
                  SizedBox(width: 4.h),
                  Text(
                    "$totalApplications Applications",
                    style:
                        TextStyleHelper.instance.body12SemiBoldPoppins.copyWith(
                      color: appTheme.black_900.withOpacity(0.6),
                      fontSize: 13.fSize,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgBasilMapLocationSolid,
                        width: 24.h,
                        height: 24.h,
                      ),
                      SizedBox(width: 4.h),
                      Expanded(
                        child: Text(
                          "${location ?? ""} ${workMode != null ? " • $workMode" : ""}",
                          style: TextStyleHelper.instance.body14MediumPoppins,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo ?? "",
                  style: TextStyleHelper.instance.body12MediumPoppins.copyWith(
                    color: appTheme.gray_400,
                    fontSize: 13.fSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

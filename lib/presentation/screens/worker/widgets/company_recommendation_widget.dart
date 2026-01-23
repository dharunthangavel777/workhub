import 'package:flutter/material.dart';
import '../../../../config/app_export.dart';
import '../../../widgets/shared/custom_image_view.dart';
import 'package:work_hub/theme/custom_colors.dart';

class CompanyRecommendationWidget extends StatelessWidget {
  final String? companyName;
  final String? logoPath;
  final bool? isVerified;
  final String? location;
  final int? openJobsCount;
  final VoidCallback? onTap;

  const CompanyRecommendationWidget({
    Key? key,
    this.companyName,
    this.logoPath,
    this.isVerified,
    this.location,
    this.openJobsCount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 2.5,
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: appTheme.white_A700,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(
            color: appTheme.black_900.withValues(alpha: 0.05),
            width: 1.h,
          ),
          boxShadow: [
            BoxShadow(
              color: appTheme.black_900.withValues(alpha: 0.05),
              blurRadius: 4.h,
              offset: Offset(0, 2.h),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 48.h,
              width: 48.h,
              padding: EdgeInsets.all(8.h),
              decoration: BoxDecoration(
                color: appTheme.gray_50,
                shape: BoxShape.circle,
              ),
              child: logoPath != null && logoPath!.isNotEmpty
                  ? CustomImageView(
                      imagePath: logoPath!,
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: Text(
                        companyName?.substring(0, 1).toUpperCase() ?? "",
                        style: TextStyleHelper.instance.headline22Bold,
                      ),
                    ),
            ),
            SizedBox(height: 12.h),
            Text(
              companyName ?? "",
              style: TextStyleHelper.instance.body14Medium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              location ?? "Remote",
              style: TextStyleHelper.instance.body12Medium.copyWith(
                color: CustomColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
              decoration: BoxDecoration(
                color: appTheme.indigo_50,
                borderRadius: BorderRadius.circular(8.h),
              ),
              child: Text(
                "${openJobsCount ?? 1} Open Jobs",
                style: TextStyleHelper.instance.body12Medium.copyWith(
                  color: appTheme.indigo_A700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

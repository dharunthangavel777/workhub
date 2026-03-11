import 'package:flutter/material.dart';
import 'package:work_hub/core/config/app_export.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'About Work Hub',
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
                  color: appTheme.white_A700_01,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(20.h),
                          decoration: BoxDecoration(
                            color: appTheme.white_A700_01,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: appTheme.gray_200.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/icons/app.png",
                            height: 80.h,
                            width: 80.h,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.business_center,
                              size: 80.h,
                              color: appTheme.indigo_A700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        "Our Mission",
                        style: TextStyleHelper.instance.body18Bold
                            .copyWith(color: appTheme.gray_900),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        "Work Hub is the ultimate platform connecting talented freelancers and job seekers with innovative companies. We strive to create a seamless experience for finding work and hiring top talent.",
                        style: TextStyleHelper.instance.body14Medium
                            .copyWith(color: appTheme.gray_700, height: 1.5),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        "What We Offer",
                        style: TextStyleHelper.instance.body16Bold
                            .copyWith(color: appTheme.gray_900),
                      ),
                      SizedBox(height: 12.h),
                      _buildFeatureItem("Advanced AI Job Matching"),
                      _buildFeatureItem("Secure Payment Escrow"),
                      _buildFeatureItem("Real-time Collaboration tools"),
                      _buildFeatureItem("Verified Professional Network"),
                      SizedBox(height: 40.h),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "Version 1.1.0",
                              style: TextStyleHelper.instance.body12Medium
                                  .copyWith(color: appTheme.gray_500),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "© 2024 Work Hub Inc. All rights reserved.",
                              style: TextStyleHelper.instance.body12Medium
                                  .copyWith(color: appTheme.gray_400),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
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

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: appTheme.indigo_A700, size: 20.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray_700),
            ),
          ),
        ],
      ),
    );
  }
}
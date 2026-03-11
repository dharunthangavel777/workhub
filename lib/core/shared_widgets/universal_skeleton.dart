import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/core/shared_widgets/predictive_shimmer.dart';

enum SkeletonType { card, circle, line, profile, square }

class UniversalSkeleton extends StatelessWidget {
  final SkeletonType type;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const UniversalSkeleton({
    super.key,
    required this.type,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  factory UniversalSkeleton.card({EdgeInsetsGeometry? margin}) =>
      UniversalSkeleton(
        type: SkeletonType.card,
        margin: margin,
      );

  factory UniversalSkeleton.profile() =>
      const UniversalSkeleton(type: SkeletonType.profile);


  factory UniversalSkeleton.circle(
          {required double size, EdgeInsetsGeometry? margin}) =>
      UniversalSkeleton(
        type: SkeletonType.circle,
        width: size,
        height: size,
        margin: margin,
      );

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SkeletonType.card:
        return _buildCardSkeleton();
      case SkeletonType.profile:
        return _buildProfileSkeleton();
      case SkeletonType.circle:
        return PredictiveShimmer(
          width: width ?? 50,
          height: height ?? 50,
          borderRadius: BorderRadius.circular((width ?? 50) / 2),
          margin: margin,
        );
      case SkeletonType.square:
        return PredictiveShimmer(
          width: width ?? 50,
          height: height ?? 50,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          margin: margin,
        );
      case SkeletonType.line:
        return PredictiveShimmer(
          width: width ?? double.infinity,
          height: height ?? 12,
          borderRadius: borderRadius ?? BorderRadius.circular(6),
          margin: margin,
        );
    }
  }

  Widget _buildCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.h),
      margin: margin ?? EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(
          color: appTheme.black_900.withValues(alpha: 0.05),
          width: 1.h,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PredictiveShimmer(width: 180.w, height: 20.h),
                    SizedBox(height: 8.h),
                    PredictiveShimmer(width: 120.w, height: 14.h),
                  ],
                ),
              ),
              SizedBox(width: 12.h),
              PredictiveShimmer(
                width: 48.h,
                height: 48.h,
                borderRadius: BorderRadius.circular(12.h),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              PredictiveShimmer(width: 80.w, height: 12.h),
              SizedBox(width: 16.w),
              PredictiveShimmer(width: 100.w, height: 12.h),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PredictiveShimmer(width: 140.w, height: 14.h),
              PredictiveShimmer(width: 60.w, height: 12.h),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildProfileSkeleton() {
    return Column(
      children: [
        PredictiveShimmer(width: double.infinity, height: 180.h),
        Padding(
          padding: EdgeInsets.all(24.h),
          child: Column(
            children: [
              PredictiveShimmer(
                width: 100.h,
                height: 100.h,
                borderRadius: BorderRadius.circular(50.h),
              ),
              SizedBox(height: 16.h),
              PredictiveShimmer(width: 200.w, height: 24.h),
              SizedBox(height: 8.h),
              PredictiveShimmer(width: 150.w, height: 16.h),
              SizedBox(height: 32.h),
              _buildStatsSkeleton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (index) => Column(
            children: [
              PredictiveShimmer(width: 40.w, height: 18.h),
              SizedBox(height: 4.h),
              PredictiveShimmer(width: 60.w, height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}




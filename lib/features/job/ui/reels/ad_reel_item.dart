import 'package:provider/provider.dart';

import 'package:qwok/core/config/app_export.dart';
import 'package:qwok/core/services/toast_service.dart';
import 'package:qwok/features/job/domain/models/ad_model.dart';
import 'package:qwok/features/job/logic/ad_controller.dart';
import 'reel_player.dart';
import 'package:url_launcher/url_launcher.dart';

class AdReelItem extends StatefulWidget {
  final AdModel ad;
  final bool isActive;

  const AdReelItem({
    super.key,
    required this.ad,
    required this.isActive,
  });

  @override
  State<AdReelItem> createState() => _AdReelItemState();
}

class _AdReelItemState extends State<AdReelItem> {
  bool _impressionLogged = false;

  @override
  void initState() {
    super.initState();
    // Log impression when the widget is initialized and apparently active
    // Ideally, we check visibility, but initState is a decent proxy for "loaded in pageview"
    // For more accuracy, logs should happen in build when likely visible or using visibility_detector
  }

  @override
  void didUpdateWidget(covariant AdReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_impressionLogged) {
      _impressionLogged = true;
      context.read<AdProvider>().logImpression(widget.ad.id);
    }
  }

  Future<void> _handleCtaClick() async {
    context.read<AdProvider>().logClick(widget.ad.id);
    final url = Uri.parse(widget.ad.ctaLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ToastService().showError("Could not open link");
    }
  }

  @override
  Widget build(BuildContext context) {
    // If active on first build, log impression
    if (widget.isActive && !_impressionLogged) {
      // Post frame callback to avoid build-phase side effects
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_impressionLogged) {
          _impressionLogged = true;
          context.read<AdProvider>().logImpression(widget.ad.id);
        }
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        ReelPlayer(
          videoUrl: widget.ad.videoUrl,
          autoPlay: widget.isActive,
          isActive: widget.isActive,
        ),

        // Gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),

        // "Sponsored" Label
        Positioned(
          top: 60.h,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20.h),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign, color: Colors.white, size: 16.h),
                SizedBox(width: 6.w),
                Text(
                  "Sponsored",
                  style: TextStyleHelper.instance.body12Medium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Info & CTA
        Positioned(
          bottom: 40.h, // Higher bottom padding to accommodate CTA
          left: 16.w,
          right: 16.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info
              Row(
                children: [
                  CustomImageView(
                    height: 40.h,
                    width: 40.h,
                    imagePath: widget.ad.userPhotoUrl,
                    radius: BorderRadius.circular(20.h),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.ad.username,
                              style:
                                  TextStyleHelper.instance.body16Bold.copyWith(
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                      blurRadius: 4, color: Colors.black45)
                                ],
                              ),
                            ),
                            SizedBox(width: 4.w),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Caption
              Text(
                widget.ad.caption,
                style: TextStyleHelper.instance.body14Medium.copyWith(
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 4, color: Colors.black45)],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 20.h),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleCtaClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.indigoA700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.ad.ctaLabel,
                        style: TextStyleHelper.instance.body16Bold
                            .copyWith(color: Colors.white),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward,
                          size: 18.h, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}




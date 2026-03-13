import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/chat/logic/chat_controller.dart';

import 'animated_typing_search_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:work_hub/features/chat/ui/chat_list_screen.dart';

class AnimatedProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String userName;
  final String welcomeMessage;
  final String? profileImage;
  final bool switchValue;
  final String firstLabel;
  final String secondLabel;
  final Function(bool)? onSwitchChanged;
  final VoidCallback? onProfileTap;
  final Color? backgroundColor;
  final double profileCompletion;
  final TextEditingController? searchController;
  final VoidCallback? onSearchTap;

  AnimatedProfileHeaderDelegate({
    required this.userName,
    required this.welcomeMessage,
    this.profileImage,
    required this.switchValue,
    required this.firstLabel,
    required this.secondLabel,
    this.onSwitchChanged,
    this.onProfileTap,
    this.backgroundColor,
    this.profileCompletion = 0,
    this.searchController,
    this.onSearchTap,
  });

  @override
  double get maxExtent => 310.h;

  @override
  double get minExtent => 120.h;

  @override
  bool shouldRebuild(covariant AnimatedProfileHeaderDelegate oldDelegate) {
    return oldDelegate.userName != userName ||
        oldDelegate.welcomeMessage != welcomeMessage ||
        oldDelegate.profileImage != profileImage ||
        oldDelegate.switchValue != switchValue ||
        oldDelegate.profileCompletion != profileCompletion ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.searchController != searchController;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Basic progress 0.0 -> 1.0
    final double maxScroll = maxExtent - minExtent;
    final double progress =
        maxScroll > 0.001 ? (shrinkOffset / maxScroll).clamp(0.0, 1.0) : 1.0;

    // Ease progress for smoother movement
    final double easeProgress = Curves.easeInOutCubic.transform(progress);

    // 1. Content Phase (Greeting, Search, Chips) - Fades out smoothly
    final double contentVisibility = (1.0 - (progress / 0.7)).clamp(0.0, 1.0);
    final double contentScale = lerpDouble(1.0, 0.8, easeProgress)!;
    final double contentSlide = -shrinkOffset * 0.4;

    // 2. Anchor Phase (Profile, Notification, Name) - Anchors late (0.7 -> 1.0)
    final double anchorVisibility = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

    // 3. Search Icon Morph Phase - Starts early to overlap with content fade (0.3 -> 1.0)
    final double searchIconVisibility =
        ((progress - 0.3) / 0.7).clamp(0.0, 1.0);

    // Elements that disappear when collapsed (Switch)
    final double switchVisibility = (1.0 - (progress / 0.5)).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Background - Prevents transparency (User Request)
        Positioned.fill(
          child: Container(
            color: backgroundColor ?? CustomColors.lightBg,
          ),
        ),
        // Content Area
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Toolbar (Persistent/Anchored elements)
                  SizedBox(
                    height: 48.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left: Profile Image & Name (Anchors when collapsed)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Profile Image - Premium Scale & Alignment
                              GestureDetector(
                                onTap: onProfileTap,
                                child: Transform.scale(
                                  scale: lerpDouble(1.2, 1.0, easeProgress)!,
                                  child: ProfileGradientRing(
                                    size: 36.h,
                                    child: CustomImageView(
                                      imagePath: profileImage ??
                                          ImageConstant.imgImage4,
                                      height: 36.h,
                                      width: 36.h,
                                      radius: BorderRadius.circular(18.h),
                                    ),
                                  ),
                                ),
                              ),
                              if (anchorVisibility > 0) ...[
                                SizedBox(width: 8.w),
                                Opacity(
                                  opacity: anchorVisibility,
                                  child: ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: 200.w),
                                    child: Text(
                                      userName,
                                      style: GoogleFonts.poppins(
                                        color: backgroundColor ==
                                                CustomColors.primaryBlue
                                            ? Colors.white
                                            : (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : CustomColors.darkText),
                                        fontSize: 19.fSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Right area: Search Icon (Collapses here) + Notification
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Collapsed Search Icon (Fades in as search bar fades out)
                              if (searchIconVisibility > 0)
                                Opacity(
                                  opacity: searchIconVisibility,
                                  child: Transform.scale(
                                    scale: searchIconVisibility,
                                    child: GestureDetector(
                                      onTap: onSearchTap,
                                      child: Container(
                                        margin: EdgeInsets.only(right: 12.w),
                                        padding: EdgeInsets.all(8.h),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                                  .withValues(alpha: 0.1)
                                              : Colors.black
                                                  .withValues(alpha: 0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: CustomImageView(
                                          imagePath: "assets/icons/search.png",
                                          color: Colors.white,
                                          height: 20.h,
                                          width: 20.h,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // Messenger Icon (Persistent/Anchors)
                              Selector<ChatProvider, int>(
                                selector: (_, p) => p.totalUnreadCount,
                                builder: (context, unreadCount, _) =>
                                    Transform.scale(
                                  scale: lerpDouble(1.0, 0.9, easeProgress)!,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ChatListScreen(),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CustomImageView(
                                          imagePath:
                                              "assets/icons/messenger.png",
                                          height: 28.h,
                                          width: 28.h,
                                          color: backgroundColor ==
                                                  CustomColors.primaryBlue
                                              ? Colors.white
                                              : (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : CustomColors.darkText),
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: -4.w,
                                            top: -4.h,
                                            child: Container(
                                              padding: EdgeInsets.all(4.h),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: backgroundColor ==
                                                          CustomColors
                                                              .primaryBlue
                                                      ? CustomColors.primaryBlue
                                                      : CustomColors.lightBg,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Text(
                                                unreadCount > 9
                                                    ? '9+'
                                                    : unreadCount.toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8.fSize,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Center: Job Switch (Zooms out as we collapse)
                        if (switchVisibility > 0)
                          Align(
                            alignment: Alignment.center,
                            child: Transform.scale(
                              scale: switchVisibility,
                              child: Opacity(
                                opacity: switchVisibility,
                                child: _buildSwitch(0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: lerpDouble(20.h, 0, easeProgress)!),
                  // Transformable Main Content (Greeting, Search, Chips)
                  if (contentVisibility > 0)
                    Transform.translate(
                      offset: Offset(0, contentSlide),
                      child: Opacity(
                        opacity: contentVisibility,
                        child: Transform.scale(
                          scale: contentScale,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting - Elegant Fade
                              RepaintBoundary(
                                child: Center(
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(
                                        fontSize: 24.fSize,
                                        color: backgroundColor ==
                                                CustomColors.primaryBlue
                                            ? Colors.white
                                            : (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : CustomColors.darkText),
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: "Hello, ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400),
                                        ),
                                        TextSpan(
                                          text: "$userName !",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 40.h),
                              // Search Bar - Professional Morph target
                              RepaintBoundary(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AnimatedTypingSearchView(
                                        controller: searchController,
                                        onChanged: (value) {
                                          // Handle search
                                        },
                                        onTap: onSearchTap,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Container(
                                      height: 54.h,
                                      width: 54.h,
                                      decoration: BoxDecoration(
                                        color: CustomColors.lightCard,
                                        borderRadius:
                                            BorderRadius.circular(16.h),
                                        border: Border.all(
                                          color: appTheme.indigo_A700
                                              .withValues(alpha: 0.1),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: CustomColors.primaryBlue,
                                        size: 24.h,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(double progress) {
    return Container(
      width: 170.w,
      height: 44.h,
      padding: EdgeInsets.all(4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22.h),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Sliding Indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            alignment:
                switchValue ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: (170.w - 8.h) / 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.h),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Text Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onSwitchChanged?.call(false),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.poppins(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w600,
                        color: !switchValue
                            ? CustomColors.primaryBlue
                            : Colors.white,
                      ),
                      child: Text(firstLabel),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onSwitchChanged?.call(true),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.poppins(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w600,
                        color: switchValue
                            ? CustomColors.primaryBlue
                            : Colors.white,
                      ),
                      child: Text(secondLabel),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileGradientRing extends StatefulWidget {
  final Widget child;
  final double size;

  const ProfileGradientRing(
      {super.key, required this.child, required this.size});

  @override
  State<ProfileGradientRing> createState() => _ProfileGradientRingState();
}

class _ProfileGradientRingState extends State<ProfileGradientRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing/Rotating Gradient Ring
        RotationTransition(
          turns: _controller,
          child: Container(
            width: widget.size + 6.h,
            height: widget.size + 6.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  appTheme.indigo_A700.withValues(alpha: 0.0),
                  appTheme.indigo_A700.withValues(alpha: 0.8),
                  Colors.blueAccent,
                  appTheme.indigo_A700.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),
        Container(
          width: widget.size + 3.h,
          height: widget.size + 3.h,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        // THE IMAGE
        widget.child,
      ],
    );
  }
}

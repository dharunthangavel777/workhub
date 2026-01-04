import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/app_export.dart';
import '../../../../data/models/carousel_slide_model.dart';
import '../../../../data/repositories/carousel_repository.dart';

class HomeCarouselWidget extends StatefulWidget {
  const HomeCarouselWidget({Key? key}) : super(key: key);

  @override
  State<HomeCarouselWidget> createState() => _HomeCarouselWidgetState();
}

class _HomeCarouselWidgetState extends State<HomeCarouselWidget> {
  final CarouselRepository _repository = CarouselRepository();
  List<CarouselSlideModel> _slides = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchSlides();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlides() async {
    try {
      final slides = await _repository.fetchSlides();
      if (mounted) {
        setState(() {
          _slides = slides;
          _isLoading = false;
        });
        _startAutoPlay();
      }
    } catch (e) {
      debugPrint("❌ Error fetching carousel slides: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (_slides.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final currentPage = _pageController.page?.toInt() ?? 0;
        final nextPage = currentPage + 1;

        if (nextPage >= _slides.length) {
          // Jump instantly to first slide without animation
          _pageController.jumpToPage(0);
        } else {
          // Animate to next slide
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 160.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: appTheme.gray_50,
          borderRadius: BorderRadius.circular(16.h),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_slides.isEmpty) {
      return const SizedBox.shrink(); // Hide if no slides
    }

    return Column(
      children: [
        SizedBox(
          height: 160.h, // Approx aspect ratio of 1080x420
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _buildCarouselItem(slide);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(CarouselSlideModel slide) {
    return GestureDetector(
      onTap: () async {
        if (slide.navType == 'external') {
          final uri = Uri.parse(slide.navUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        } else if (slide.navType == 'internal') {
          Navigator.pushNamed(context, slide.navUrl);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.h),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.h),
          child: CachedNetworkImage(
            imageUrl: slide.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) {
              debugPrint("❌ Error loading image ${slide.imageUrl}: $error");
              return const Icon(Icons.error);
            },
          ),
        ),
      ),
    );
  }
}

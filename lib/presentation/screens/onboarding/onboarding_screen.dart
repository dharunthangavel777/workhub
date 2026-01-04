import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/custom_colors.dart';

import '../auth/unified_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Connect Agents\nwith Talent",
      description:
          "A unified platform where agents upload job orders and professional contractors discover their next opportunity.",
      image: 'assets/icons/app.png',
    ),
    OnboardingData(
      title: "Smart Work Order\nManagement",
      description:
          "Seamlessly submit work plans, track job assignments, and manage project approvals in a single, streamlined workflow.",
      image: 'assets/icons/app.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? CustomColors.primaryBlue
                              : CustomColors.lightBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Buttons
                  if (_currentPage == _pages.length - 1)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _navigateToLogin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Get Started",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.primaryBlue,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for the main illustration/logo
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: CustomColors.primaryBlue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              data.image,
              width: 120,
              height: 120,
              color: CustomColors.primaryBlue, // Tinting it blue as requested
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: CustomColors.primaryBlue,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CustomColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

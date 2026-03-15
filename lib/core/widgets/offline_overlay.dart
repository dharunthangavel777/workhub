import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qwok/core/services/connectivity_service.dart';

class OfflineOverlay extends StatelessWidget {
  final Widget child;

  const OfflineOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<ConnectivityService>(
          builder: (context, connectivity, _) {
            if (connectivity.isOnline) return const SizedBox.shrink();

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 6 * value,
                    sigmaY: 6 * value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4 * value),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon container
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7F1D1D)
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi_off_rounded,
                                color: Color(0xFFEF4444),
                                size: 28,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Title
                            Text(
                              "You're Offline",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Description
                            Text(
                              "We couldn’t connect to the network.\nYour data is saved locally and will sync once you're back online.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // CTA Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => connectivity.checkStatus(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "Retry Connection",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}




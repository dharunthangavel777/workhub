import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../logic/providers/auth_provider.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  bool _wasGuest = false;
  @override
  void initState() {
    super.initState();
    _wasGuest = context.read<AuthProvider>().isGuest;
    // Safe check: if we are already authenticated (e.g. state updated quickly), pop back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handleClose() {
    if (_wasGuest) {
      context.read<AuthProvider>().setGuestMode(true);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background accents
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: CustomColors.primaryBlue.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const Hero(
                      tag: 'logo',
                      child: Icon(
                        FontAwesomeIcons.briefcase,
                        size: 64,
                        color: CustomColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Welcome to\n${AppStrings.appName}",
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "The premium marketplace for agents and professional talent.",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    if (auth.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Column(
                      children: [
                        _LoginButton(
                          label: "Continue with Google",
                          icon: FontAwesomeIcons.google,
                          color: Colors.black,
                          textColor: Colors.white,
                          isLoading: auth.isLoading,
                          onPressed: () async {
                            await auth.signInWithGoogle();
                            if (auth.isAuthenticated && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _enterGuestMode,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Skip for now",
                            style: GoogleFonts.inter(
                              color: CustomColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        "By continuing, you agree to our Terms and conditions",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enterGuestMode() {
    context.read<AuthProvider>().setGuestMode(true);
    Navigator.of(context).pop();
  }
}

class _LoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

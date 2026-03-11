import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:work_hub/constants/app_strings.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/core/theme/custom_colors.dart';
import 'package:work_hub/core/theme/text_style_helper.dart';

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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Login Illustration to match Onboarding style
                Expanded(
                  flex: 3,
                  child: Image.asset(
                    'assets/images/login.gif',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 40),

                // Text Content
                Column(
                  children: [
                    Text(
                      AppStrings.welcomeToAppName,
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.headline30Bold.copyWith(
                        color: CustomColors.primaryBlue,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appTagline,
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.body16Regular.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Error Message Handling
                if (auth.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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

                // Action Buttons
                Column(
                  children: [
                    _LoginButton(
                      label: AppStrings.continueWithGoogle,
                      icon: FontAwesomeIcons.google,
                      color: CustomColors.primaryBlue,
                      textColor: Colors.white,
                      isLoading: auth.isLoading,
                      onPressed: () async {
                        await auth.signInWithGoogle();
                        if (auth.isAuthenticated && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _enterGuestMode,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppStrings.skipForNow,
                        style: TextStyleHelper.instance.body16Regular.copyWith(
                          color: CustomColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Text(
                  AppStrings.termsAgreement,
                  style: TextStyleHelper.instance.body12Medium.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
                    style: TextStyleHelper.instance.body16SemiBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

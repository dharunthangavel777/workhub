import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/core/theme/custom_colors.dart';
import 'package:work_hub/core/services/initialization_service.dart';
import 'package:work_hub/core/widgets/work_hub_loading.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start initialization when the splash screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure splash is visible for at least 2 seconds for smooth transition
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.read<AppInitializationService>().initialize(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primaryBlue,
      body: Consumer<AppInitializationService>(
        builder: (context, initService, child) {
          if (initService.error != null) {
            return _buildError(initService.error!);
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding Logo in Center as requested
                Image.asset(
                  'assets/icons/app.png',
                  width: 140,
                  height: 140,
                  // If the image is already white/transparent, this works.
                  // If not, we might need a color filter or a different asset.
                ),
                const SizedBox(height: 60),
                const WorkHubLoading(
                  color: Colors.white,
                  size: 40,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "Initialization Failed",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () =>
                  context.read<AppInitializationService>().initialize(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: CustomColors.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'features/job/logic/job_controller.dart';
import 'features/chat/logic/chat_controller.dart';
import 'features/reel/logic/reel_controller.dart';
import 'features/job/logic/ad_controller.dart';
import 'features/common/services/ad_service.dart';
import 'package:work_hub/core/services/connectivity_service.dart';
import 'package:work_hub/core/widgets/offline_overlay.dart';
import 'package:work_hub/firebase_options.dart';
import 'features/ai/logic/resume_parse_provider.dart';
import 'core/services/initialization_service.dart';
import 'features/common/ui/splash_screen.dart';
import 'features/auth/ui/auth_loading_screen.dart';

import 'features/auth/models/user.dart';
import 'features/onboarding/ui/onboarding_screen.dart';
import 'features/common/navigation/worker_navigation.dart';
import 'features/auth/ui/worker_profile_completion_screen.dart';
import 'features/settings/ui/settings_screen.dart';
import 'features/job/ui/withdrawal_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Foundation Initializations (Required for Providers)
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Global Error Handler for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("🔴 Flutter Error: ${details.exception}");
  };

  // Global Error Handler for asynchronous errors (Zone)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint("🔴 Async Error: $error");
    return true; // Returning true means we've handled the error
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInitializationService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ReelProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => AdService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => ResumeParseProvider()),
      ],
      child: const WorkHubApp(),
    ),
  );
}

class WorkHubApp extends StatelessWidget {
  const WorkHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const StartupFlow(),
      builder: (context, child) {
        return OfflineOverlay(child: child!);
      },
      routes: {
        '/main': (context) => const RootWrapper(),
        '/settings': (context) => const SettingsScreen(),
        '/withdrawal': (context) => const WithdrawalScreen(),
      },
    );
  }
}

class StartupFlow extends StatelessWidget {
  const StartupFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final initService = context.watch<AppInitializationService>();

    if (!initService.isInitialized) {
      return const SplashScreen();
    }

    return const RootWrapper();
  }
}

// ... (existing code for StartupFlow)

class RootWrapper extends StatelessWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Initial/Loading States
    if (auth.status == AuthStatus.initial ||
        auth.status == AuthStatus.loading) {
      return const AuthLoadingScreen();
    }

    // 2. Unauthenticated State
    if (!auth.isAuthenticated && !auth.isGuest) {
      return const OnboardingScreen();
    }

    // 3. Error State
    if (auth.status == AuthStatus.error || auth.errorMessage != null) {
      return _GlobalErrorScreen(
        message: auth.errorMessage ?? "An unexpected error occurred",
        onRetry: () => auth.signOut(),
      );
    }

    // 4. Authenticated but Data Syncing (No Cache yet)
    if (auth.isAuthenticated && auth.userModel == null && !auth.isGuest) {
      return const AuthLoadingScreen();
    }

    // 5. Role-based Navigation (Simplified for Workers/Guests)
    if (auth.isGuest || auth.userModel == null) {
      return const WorkerNavigation();
    }

    final user = auth.userModel!;

    if (user.role == UserRole.admin) {
      return const _AdminWebNotice();
    }

    if (user.isFirstLogin) {
      return const WorkerProfileCompletionScreen();
    }
    return const WorkerNavigation();
  }
}

class _GlobalErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GlobalErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                "Oops! Something went wrong",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Reset & Try Again"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminWebNotice extends StatelessWidget {
  const _AdminWebNotice();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.computer, size: 64, color: Color(0xFF2196F3)),
              const SizedBox(height: 24),
              const Text(
                "Admin Web Panel Required",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Platform management has been migrated to the standalone Web Panel for enhanced security and functionality.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              const Text(
                "Please access admin_panel.html from your browser.",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Log Out"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

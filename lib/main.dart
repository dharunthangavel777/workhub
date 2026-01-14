import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/job_provider.dart';
import 'logic/providers/chat_provider.dart';
import 'logic/providers/reel_provider.dart';
import 'data/models/user_model.dart';

import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/navigation/worker_navigation.dart';
import 'presentation/navigation/business_owner_navigation.dart';
import 'presentation/screens/auth/worker_profile_completion_screen.dart';
import 'presentation/screens/auth/client_profile_completion_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

import 'presentation/screens/owner/subscription_selection_screen.dart';
import 'presentation/screens/worker/withdrawal_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'logic/services/notification_service.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    // Initialize Push Notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } on FirebaseException catch (e) {
    // Ignore duplicate app error, but log it
    if (e.code == 'duplicate-app') {
      debugPrint('Firebase already initialized, continuing...');
    } else {
      // For other Firebase errors, show error screen
      debugPrint('Firebase initialization error: $e');
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Firebase Initialization Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
  } catch (e, stackTrace) {
    debugPrint('Unexpected error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ReelProvider()),
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
      home: const SplashScreen(),
      routes: {
        '/main': (context) => const RootWrapper(),
        '/settings': (context) => const SettingsScreen(),
        '/withdrawal': (context) => const WithdrawalScreen(),
        '/become_hirer': (context) => const ClientProfileCompletionScreen(),
      },
    );
  }
}

class RootWrapper extends StatelessWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Initial/Loading States
    if (auth.status == AuthStatus.initial ||
        auth.status == AuthStatus.loading) {
      return const Scaffold(backgroundColor: Color(0xFF003DEC));
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

    // 4. Role-based Navigation (Optimistic for Workers/Guests)
    if (auth.isGuest || auth.userModel == null) {
      return const WorkerNavigation();
    }

    final user = auth.userModel!;

    if (user.role == UserRole.worker || user.role == UserRole.none) {
      if (user.isFirstLogin) {
        return const WorkerProfileCompletionScreen();
      }
      return const WorkerNavigation();
    }

    if (user.role == UserRole.businessOwner) {
      if (user.isTrialActive && !user.hasSeenSubscription) {
        return const SubscriptionSelectionScreen();
      }
      return const BusinessOwnerNavigation();
    }

    if (user.role == UserRole.admin) {
      return const _AdminWebNotice();
    }

    // Fallback
    return _GlobalErrorScreen(
      message: "Unknown user role or state",
      onRetry: () => auth.signOut(),
    );
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
                child: const Text("Log Out"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final SharedPreferences prefs;

  try {
    debugPrint("🚀 Starting Hazaribagh Pulse Initialization...");
    // Initialize Firebase pointing to the auto-generated options file
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase Initialized cleanly.");

    // Initialize App Check to use a Debug Provider locally safely on emulators
    try {
      if (kDebugMode) {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidDebugProvider(),
          providerApple: const AppleDebugProvider(),
        );
        debugPrint("✅ AppCheck (Debug) Initialized.");
      } else {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
          providerApple: const AppleAppAttestProvider(),
        );
        debugPrint("✅ AppCheck (Prod Mode) Initialized.");
      }
    } catch (e) {
      debugPrint("⚠️ AppCheck activation failed (Non-fatal): $e");
    }

    // Initialize SharedPreferences
    prefs = await SharedPreferences.getInstance();
    debugPrint("✅ SharedPreferences Initialized.");

  } catch (e, stack) {
    debugPrint("🛑 CRITICAL STARTUP ERROR: $e");
    debugPrint("Stacktrace: $stack");
    // If Firebase completely fails to start, boot to a safe error screen to prevent blank disconnection
    runApp(StartupErrorApp(error: e.toString()));
    return;
  }

  runApp(
    // ProviderScope is required by Riverpod to wrap the entire app
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HazaribaghPulseApp(),
    ),
  );
}

class StartupErrorApp extends StatelessWidget {
  final String error;
  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start application',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HazaribaghPulseApp extends ConsumerWidget {
  const HazaribaghPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the goRouter instance from the Riverpod provider
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Hazaribagh Pulse',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}


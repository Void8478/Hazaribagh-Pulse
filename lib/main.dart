import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final SharedPreferences prefs;

  try {
    debugPrint("🚀 Starting Hazaribagh Pulse Initialization...");

    // Initialize Supabase (Replace YOUR_SUPABASE_URL and YOUR_SUPABASE_ANON_KEY)
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://beudtyljcymeeklihshg.supabase.co'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJldWR0eWxqY3ltZWVrbGloc2hnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MjY3OTYsImV4cCI6MjA5MTIwMjc5Nn0.APkYQf3k3xacQY89PnAmgQIrSVyhPJSFCZ8ALZhby2E'),
    );
    debugPrint("✅ Supabase Initialized.");

    // Initialize SharedPreferences
    prefs = await SharedPreferences.getInstance();
    debugPrint("✅ SharedPreferences Initialized.");

  } catch (e, stack) {
    debugPrint("🛑 CRITICAL STARTUP ERROR: $e");
    debugPrint("Stacktrace: $stack");
    // If Supabase startup fails completely, boot to a safe error screen.
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

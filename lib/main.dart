import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

const String _defaultSupabaseUrl = 'https://beudtyljcymeeklihshg.supabase.co';
const String _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJldWR0eWxqY3ltZWVrbGloc2hnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MjY3OTYsImV4cCI6MjA5MTIwMjc5Nn0.APkYQf3k3xacQY89PnAmgQIrSVyhPJSFCZ8ALZhby2E';

String _resolveSupabaseUrl() {
  final rawUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  ).trim();

  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException(
      'Invalid Supabase URL. Use https://YOUR_PROJECT_REF.supabase.co',
    );
  }

  if (uri.scheme != 'https') {
    throw const FormatException(
      'Supabase URL must use https://YOUR_PROJECT_REF.supabase.co',
    );
  }

  if (uri.host != 'supabase.co' && !uri.host.endsWith('.supabase.co')) {
    throw const FormatException(
      'Supabase URL host must end with .supabase.co',
    );
  }

  if (uri.pathSegments.isNotEmpty) {
    throw const FormatException(
      'Supabase URL must not include extra paths like /auth/v1/token',
    );
  }

  return uri.replace(path: '').toString().replaceAll(RegExp(r'/$'), '');
}

String _resolveSupabaseAnonKey() {
  final rawKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabaseAnonKey,
  ).trim();

  if (rawKey.isEmpty) {
    throw const FormatException('Supabase anon key is missing.');
  }

  final parts = rawKey.split('.');
  if (parts.length != 3) {
    throw const FormatException('Supabase anon key must be a valid JWT.');
  }

  try {
    final normalizedPayload = base64Url.normalize(parts[1]);
    final payload = utf8.decode(base64Url.decode(normalizedPayload));

    if (payload.contains('"role":"service_role"')) {
      throw const FormatException(
        'Use the public anon key from Supabase Dashboard, not service_role.',
      );
    }

    if (!payload.contains('"role":"anon"')) {
      throw const FormatException(
        'Supabase key must be the public anon key from Project Settings > API.',
      );
    }
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException(
      'Supabase anon key must be a valid public anon JWT.',
    );
  }

  return rawKey;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  late final SharedPreferences prefs;

  try {
    debugPrint('Starting Hazaribagh Pulse initialization...');

    await Supabase.initialize(
      url: _resolveSupabaseUrl(),
      anonKey: _resolveSupabaseAnonKey(),
    );
    debugPrint('Supabase initialized.');

    prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized.');
  } catch (e, stack) {
    debugPrint('Critical startup error: $e');
    debugPrint('Stacktrace: $stack');
    runApp(StartupErrorApp(error: e.toString()));
    return;
  }

  runApp(
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
            padding: const EdgeInsets.all(24),
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
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Hazaribagh Pulse',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _NoGlowScrollBehavior(),
      builder: (context, child) {
        final isDark =
            Theme.of(context).brightness == Brightness.dark;
        return ColoredBox(
          color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _NoGlowScrollBehavior extends MaterialScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

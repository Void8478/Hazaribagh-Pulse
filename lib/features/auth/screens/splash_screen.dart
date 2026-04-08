import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';

/// Splash screen shown while Firebase auth + profile verification is resolving.
/// Has a built-in safety timeout — if startup takes longer than 12 seconds,
/// it displays a retry button so the user is never permanently stuck.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showTimeout = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Safety net: if splash is still visible after 12 seconds, show timeout UI
    _timeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) {
        setState(() => _showTimeout = true);
        debugPrint('⏰ [SplashScreen] Timeout reached — showing retry options');
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state so GoRouter redirect triggers rebuild when state changes
    final authState = ref.watch(authProvider);
    final firebaseAuth = ref.watch(authStateChangesProvider);
    
    debugPrint('🎨 [SplashScreen] build — authState: $authState, '
               'firebaseAuth isLoading: ${firebaseAuth.isLoading}');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(
              Icons.location_city_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hazaribagh Pulse',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            
            if (_showTimeout) ...[
              // Timeout state — show retry/skip options
              const Text(
                'Taking longer than expected...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Force re-initialization by invalidating the auth provider
                  setState(() => _showTimeout = false);
                  ref.invalidate(authProvider);
                  ref.invalidate(authStateChangesProvider);
                  // Reset timer
                  _timeoutTimer?.cancel();
                  _timeoutTimer = Timer(const Duration(seconds: 12), () {
                    if (mounted) setState(() => _showTimeout = true);
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ] else ...[
              // Normal loading state
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withAlpha(200),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

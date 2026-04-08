import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B0F14);
    const backgroundAccent = Color(0xFF121821);
    const foregroundMuted = Color(0xFFB7C0CC);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [background, backgroundAccent],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  Icons.location_city,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Discover Hazaribagh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Find top trusted local businesses, authentic events, and real reviews from your community.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: foregroundMuted),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

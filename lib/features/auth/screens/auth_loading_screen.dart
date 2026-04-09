import 'package:flutter/material.dart';

/// Compatibility loading screen kept for any legacy routes.
/// Auth routing no longer relies on this screen to complete setup.
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0B0F14);
    const bgDark2 = Color(0xFF121821);
    const goldLight = Color(0xFFD4A017);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgDark, bgDark2],
          ),
        ),
        child: SafeArea(
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 44,
                  color: goldLight,
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(goldLight),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Preparing your experience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

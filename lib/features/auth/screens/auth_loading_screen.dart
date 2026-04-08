import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_provider.dart';

/// Shown immediately after a successful login or confirmed signup.
/// Performs any background setup, then navigates to the main app.
class AuthLoadingScreen extends ConsumerStatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  ConsumerState<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends ConsumerState<AuthLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  Timer? _safetyTimer;
  Timer? _messageTimer;
  int _messageIndex = 0;

  static const _messages = [
    'Setting up your account…',
    'Almost there…',
    'Preparing your experience…',
    'Just a moment…',
  ];

  @override
  void initState() {
    super.initState();

    // ── Entry animation ──────────────────────────────────────────────────
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();

    // ── Cycle loading messages ───────────────────────────────────────────
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });

    // ── Safety fallback: go to home after 6 seconds regardless ───────────
    _safetyTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        debugPrint('⏰ [AuthLoadingScreen] Safety timeout — navigating to home');
        ref.read(authProvider.notifier).markAppReady();
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _safetyTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When the router detects readyForApp it will push '/', but we also
    // listen here so we can cancel timers before Go Router does the redirect.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!next.readyForApp && (prev?.readyForApp ?? false)) {
        // readyForApp just turned false — router already redirected
        _safetyTimer?.cancel();
        _messageTimer?.cancel();
      }
    });

    const bgDark = Color(0xFF0B0F14);
    const bgDark2 = Color(0xFF121821);
    const gold = Color(0xFFB8860B);
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo circle ───────────────────────────────────────
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gold.withAlpha(18),
                        border:
                            Border.all(color: gold.withAlpha(70), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withAlpha(30),
                            blurRadius: 40,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 44,
                        color: goldLight,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── App name ──────────────────────────────────────────
                    const Text(
                      'Hazaribagh Pulse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Loading indicator ─────────────────────────────────
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          goldLight.withAlpha(200),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Cycling message ───────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: Text(
                        _messages[_messageIndex],
                        key: ValueKey(_messageIndex),
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Preparing your experience',
                      style: TextStyle(
                        color: Colors.white.withAlpha(100),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

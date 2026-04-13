import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _coldStartMinimumDuration = Duration(seconds: 3);
  static const Duration _authTransitionMinimumDuration = Duration(seconds: 2);

  bool _showExtendedLoading = false;
  Timer? _timeoutTimer;
  Timer? _minimumSplashTimer;
  bool _startupRequested = false;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.965, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _glowAnimation = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    final authState = ref.read(authProvider);
    _startMinimumSplashTimer(
      authState.isInitializing
          ? _coldStartMinimumDuration
          : _authTransitionMinimumDuration,
    );
    _startTimeoutTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _startupRequested) return;
      final authState = ref.read(authProvider);
      if (authState.isInitializing) {
        ref.read(startupMinimumSplashDurationProvider.notifier).reset();
        _startupRequested = true;
        ref.read(authProvider.notifier).startBootstrapIfNeeded();
        return;
      }
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      setState(() => _showExtendedLoading = true);
    });
  }

  void _startMinimumSplashTimer(Duration duration) {
    _minimumSplashTimer?.cancel();
    _minimumSplashTimer = Timer(duration, () {
      if (!mounted) return;
      ref.read(startupMinimumSplashDurationProvider.notifier).complete();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _minimumSplashTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasInitializationError = authState.initializationError != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusText = hasInitializationError
        ? 'We hit a problem loading your account'
        : (_showExtendedLoading
              ? 'Still connecting securely...'
              : 'Checking your session...');

    return Scaffold(
      backgroundColor: const Color(0xFF071019),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF071019),
                  const Color(0xFF0C1621),
                  colorScheme.primary.withValues(alpha: 0.16),
                ],
                stops: const [0.0, 0.62, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -20,
                  child: _GlowOrb(
                    size: 220,
                    color: colorScheme.primary.withValues(alpha: 0.16),
                    scale: _glowAnimation.value,
                  ),
                ),
                Positioned(
                  left: -50,
                  bottom: -70,
                  child: _GlowOrb(
                    size: 240,
                    color: colorScheme.secondary.withValues(alpha: 0.10),
                    scale: 1.12 - ((_glowAnimation.value - 1) * 0.8),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SweepLinesPainter(
                        progress: _animationController.value,
                        accent: Colors.white.withValues(alpha: 0.045),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Local discovery, refined',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withValues(alpha: 0.74),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'Hazaribagh\nPulse',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -2,
                                          height: 0.95,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 290,
                                  ),
                                  child: Text(
                                    'A calmer, more trustworthy way to find places, community updates, and moments around the city.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.62,
                                      ),
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    18,
                                    18,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    color: Colors.white.withValues(alpha: 0.05),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _LoadingSignature(
                                        progress: _animationController.value,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(height: 18),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 240,
                                        ),
                                        child: Text(
                                          statusText,
                                          key: ValueKey(statusText),
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.84,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        hasInitializationError
                                            ? 'You can safely retry bootstrap without restarting the app.'
                                            : (_showExtendedLoading
                                                  ? 'We are retrying once automatically before showing an error.'
                                                  : 'Securing your session and preparing a smooth local feed.'),
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.54,
                                              ),
                                              height: 1.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasInitializationError) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    authState.initializationError!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.tonalIcon(
                                    onPressed: authState.isInitializing
                                        ? null
                                        : () {
                                            ref
                                                .read(
                                                  startupMinimumSplashDurationProvider
                                                      .notifier,
                                                )
                                                .reset();
                                            setState(
                                              () =>
                                                  _showExtendedLoading = false,
                                            );
                                            _startMinimumSplashTimer(
                                              _coldStartMinimumDuration,
                                            );
                                            _startTimeoutTimer();
                                            _startupRequested = true;
                                            ref
                                                .read(authProvider.notifier)
                                                .retryInitialization();
                                          },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Try Again'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF09141D),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.scale,
  });

  final double size;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.22),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingSignature extends StatelessWidget {
  const _LoadingSignature({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      height: 40,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          FractionallySizedBox(
            widthFactor: 0.22 + (0.56 * Curves.easeInOut.transform(progress)),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.28), color, Colors.white],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment(
              -0.92 + (1.84 * Curves.easeInOut.transform(progress)),
              0,
            ),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.36),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SweepLinesPainter extends CustomPainter {
  const _SweepLinesPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final normalized = (progress + (i * 0.18)) % 1;
      final radius = size.shortestSide * (0.26 + normalized * 0.52);
      paint.color = accent.withValues(alpha: math.max(0, 0.10 - (i * 0.02)));
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.48),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SweepLinesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accent != accent;
  }
}

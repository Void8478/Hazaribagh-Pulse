import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/app_navigation_shell.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/email_login_screen.dart';
import '../../features/auth/screens/email_signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/complete_profile_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/auth_loading_screen.dart';
import '../../features/auth/services/auth_provider.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/explore/screens/category_results_screen.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/reviews/screens/reviews_list_screen.dart';
import '../../features/reviews/screens/write_review_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/rankings/screens/rankings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/profile/screens/privacy_settings_screen.dart';
import '../../features/profile/screens/help_center_screen.dart';
import '../../features/profile/screens/send_feedback_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final supabaseUser = ref.watch(authStateChangesProvider);
  final auth = ref.watch(authProvider);

  debugPrint('🧭 [Router] rebuild — auth: $auth, '
      'supabaseUser isLoading: ${supabaseUser.isLoading}, '
      'supabaseUser: ${supabaseUser.hasValue ? (supabaseUser.value?.id ?? 'null') : 'not-yet'}');

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final currentPath = state.matchedLocation;

      // ── GATE 1: Startup initialization in progress ──────────────────────
      if (auth.isInitializing) {
        debugPrint('🧭 [Router] GATE 1 — initializing, stay on splash');
        return currentPath == '/splash' ? null : '/splash';
      }

      // ── GATE 2: Supabase stream not yet emitted ─────────────────────────
      if (supabaseUser.isLoading) {
        debugPrint('🧭 [Router] GATE 2 — stream loading, stay on splash');
        return currentPath == '/splash' ? null : '/splash';
      }

      // ── GATE 3: Email verification required ────────────────────────────
      // User signed up / tried to log in but email is not confirmed yet.
      if (auth.emailVerificationPending) {
        debugPrint('🧭 [Router] GATE 3 — email verification pending');
        if (currentPath != '/verify-email') return '/verify-email';
        return null;
      }

      // ── GATE 4: Profile check done, ready to enter app ─────────────────
      // Show the loading/setup screen, then the router will redirect from there.
      if (auth.readyForApp) {
        debugPrint('🧭 [Router] GATE 4 — readyForApp, show loading screen');
        if (currentPath != '/auth-loading') return '/auth-loading';
        return null;
      }

      // ── Standard auth / routing logic ──────────────────────────────────
      final bool isAuth =
          supabaseUser.hasValue && supabaseUser.value != null;
      final bool needsProfile = auth.needsProfileCompletion;

      final isAuthFlow = currentPath.startsWith('/login') ||
          currentPath == '/onboarding' ||
          currentPath.startsWith('/email-') ||
          currentPath == '/forgot-password' ||
          currentPath == '/verify-email' ||
          currentPath == '/auth-loading';

      debugPrint('🧭 [Router] isAuth=$isAuth, needsProfile=$needsProfile, '
          'currentPath=$currentPath, isAuthFlow=$isAuthFlow');

      if (isAuth) {
        if (needsProfile) {
          if (currentPath != '/complete-profile') {
            debugPrint('🧭 [Router] → /complete-profile');
            return '/complete-profile';
          }
          return null;
        }
        // Authenticated and profile complete — boot out of all auth screens
        if (isAuthFlow || currentPath == '/splash' || currentPath == '/complete-profile') {
          debugPrint('🧭 [Router] → / (auth complete)');
          return '/';
        }
      } else {
        // Not authenticated — send to onboarding unless already in auth flow
        if (!isAuthFlow) {
          debugPrint('🧭 [Router] → /onboarding (unauthenticated)');
          return '/onboarding';
        }
      }

      debugPrint('🧭 [Router] → no redirect, staying on $currentPath');
      return null;
    },
    routes: [
      // ── Auth screens ────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/email-login',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/email-signup',
        builder: (context, state) => const EmailSignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      // ── New: email verification & auth loading ──────────────────────────
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          // Pass the pending email from AuthState into the screen.
          // We read it from the RouterProvider's ref via extra, or pull from
          // the provider directly inside the widget.
          return const _VerifyEmailWrapper();
        },
      ),
      GoRoute(
        path: '/auth-loading',
        builder: (context, state) => const AuthLoadingScreen(),
      ),

      // ── Profile sub-screens ─────────────────────────────────────────────
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const SendFeedbackScreen(),
      ),

      // ── Content screens ─────────────────────────────────────────────────
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) => ListingDetailScreen(
          listingId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'reviews',
            builder: (context, state) => ReviewsListScreen(
              listingId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'write-review',
            builder: (context, state) => WriteReviewScreen(
              listingId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),

      // ── Main shell (bottom nav) ─────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (_, _) => const ExploreScreen(),
                routes: [
                  GoRoute(
                    path: 'category/:name',
                    builder: (context, state) => CategoryResultsScreen(
                      categoryName: state.pathParameters['name']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/events', builder: (_, _) => const EventsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/rankings', builder: (_, _) => const RankingsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Thin wrapper so the verification screen can read pendingEmail from the provider
// without needing it passed via GoRouter extras.
// ---------------------------------------------------------------------------
class _VerifyEmailWrapper extends ConsumerWidget {
  const _VerifyEmailWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authProvider).pendingEmail ?? '';
    return EmailVerificationScreen(email: email);
  }
}

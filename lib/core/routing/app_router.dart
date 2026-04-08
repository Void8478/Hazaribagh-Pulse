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
  // Watch the auth state changes (Firebase user)
  final firebaseAuthUser = ref.watch(authStateChangesProvider);
  final authNotifierState = ref.watch(authProvider);

  debugPrint('🧭 [Router] Provider rebuild — authNotifier: $authNotifierState, '
             'firebaseAuth isLoading: ${firebaseAuthUser.isLoading}, '
             'firebaseAuth hasValue: ${firebaseAuthUser.hasValue}, '
             'firebaseAuth value: ${firebaseAuthUser.hasValue ? (firebaseAuthUser.value?.uid ?? 'null') : 'not-yet'}');

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      
      // GATE 1: AuthNotifier is still initializing
      if (authNotifierState.isInitializing) {
        debugPrint('🧭 [Router] redirect: GATE 1 — AuthNotifier initializing, staying on splash');
        return currentPath == '/splash' ? null : '/splash';
      }

      // GATE 2: Firebase Auth stream has not emitted yet
      if (firebaseAuthUser.isLoading) {
        debugPrint('🧭 [Router] redirect: GATE 2 — Firebase auth stream loading, staying on splash');
        return currentPath == '/splash' ? null : '/splash';
      }

      final bool isAuth = firebaseAuthUser.hasValue && firebaseAuthUser.value != null;
      final bool needsProfile = authNotifierState.needsProfileCompletion;
      
      final isAuthFlow = currentPath.startsWith('/login') || 
                         currentPath == '/onboarding' ||
                         currentPath.startsWith('/email-') ||
                         currentPath == '/forgot-password';

      debugPrint('🧭 [Router] redirect: isAuth=$isAuth, needsProfile=$needsProfile, '
                 'currentPath=$currentPath, isAuthFlow=$isAuthFlow');

      if (isAuth) {
        if (needsProfile) {
          if (currentPath != '/complete-profile') {
            debugPrint('🧭 [Router] → Redirecting to /complete-profile (needs profile)');
            return '/complete-profile';
          }
          return null;
        }

        if (isAuthFlow || currentPath == '/splash' || currentPath == '/complete-profile') {
          debugPrint('🧭 [Router] → Redirecting authenticated user to / (home)');
          return '/';
        }
      } else {
        if (!isAuthFlow) {
          debugPrint('🧭 [Router] → Redirecting unauthenticated user to /onboarding');
          return '/onboarding'; 
        }
      }
      
      debugPrint('🧭 [Router] → No redirect needed, staying on $currentPath');
      return null;
    },
    routes: [
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
      // Profile sub-screens (top-level for back navigation)
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/explore', 
              builder: (context, state) => const ExploreScreen(),
              routes: [
                GoRoute(
                  path: 'category/:name',
                  builder: (context, state) => CategoryResultsScreen(
                    categoryName: state.pathParameters['name']!,
                  ),
                ),
              ],
            )
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/events', builder: (context, state) => const EventsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/rankings', builder: (context, state) => const RankingsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

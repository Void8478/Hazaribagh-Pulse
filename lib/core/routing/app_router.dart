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

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Watch the auth state changes (Firebase user)
  final firebaseAuthUser = ref.watch(authStateChangesProvider);
  final authNotifierState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // If we are still initializing the auth notifier asynchronously, lock to splash
      if (authNotifierState.isInitializing) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      // If Firebase Auth stream is still loading, wait on splash
      if (firebaseAuthUser.isLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      final bool isAuth = firebaseAuthUser.value != null;
      final bool needsProfile = authNotifierState.needsProfileCompletion;
      
      final isAuthFlow = state.matchedLocation.startsWith('/login') || 
                         state.matchedLocation == '/onboarding' ||
                         state.matchedLocation.startsWith('/email-') ||
                         state.matchedLocation == '/forgot-password';

      if (isAuth) {
        // If logged in but profile is incomplete, force to /complete-profile
        if (needsProfile) {
          if (state.matchedLocation != '/complete-profile') return '/complete-profile';
          return null;
        }

        // If logged in completely, prevent visiting auth flows, splash, or complete-profile
        if (!needsProfile && (isAuthFlow || state.matchedLocation == '/splash' || state.matchedLocation == '/complete-profile')) {
          return '/';
        }
      } else {
        // If not authenticated, ensure they can only visit auth flows
        if (!isAuthFlow) return '/onboarding'; 
      }
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

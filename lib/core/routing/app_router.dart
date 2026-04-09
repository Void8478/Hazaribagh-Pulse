import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/auth_loading_screen.dart';
import '../../features/auth/screens/email_login_screen.dart';
import '../../features/auth/screens/email_signup_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/posts/screens/post_detail_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/services/auth_provider.dart';
import '../../features/content/screens/create_event_screen.dart';
import '../../features/content/screens/create_place_screen.dart';
import '../../features/content/screens/create_post_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/explore/screens/category_results_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/help_center_screen.dart';
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/profile/screens/privacy_settings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/profile/screens/send_feedback_screen.dart';
import '../../features/rankings/screens/rankings_screen.dart';
import '../../features/reviews/screens/reviews_list_screen.dart';
import '../../features/reviews/screens/write_review_screen.dart';
import '../widgets/app_navigation_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(
    authProvider.select(
      (value) => (
        isLoading: value.isLoading,
        isInitializing: value.isInitializing,
        isAuthenticated: value.isAuthenticated,
        initializationError: value.initializationError,
        emailVerificationPending: value.emailVerificationPending,
      ),
    ),
  );
  final hasMetMinimumSplashDuration = ref.watch(
    startupMinimumSplashDurationProvider,
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      final isAuthenticated = auth.isAuthenticated;
      final isAuthFlow = currentPath == '/splash' ||
          currentPath == '/onboarding' ||
          currentPath == '/login' ||
          currentPath == '/email-login' ||
          currentPath == '/email-signup' ||
          currentPath == '/forgot-password' ||
          currentPath == '/verify-email' ||
          currentPath == '/auth-loading';

      if (auth.isLoading && isAuthFlow && currentPath != '/splash') {
        return '/splash';
      }

      if (currentPath == '/splash' && !hasMetMinimumSplashDuration) {
        return null;
      }

      if (auth.isInitializing) {
        return currentPath == '/splash' ? null : '/splash';
      }

      if (auth.initializationError != null && !isAuthenticated) {
        return currentPath == '/splash' ? null : '/splash';
      }

      if (auth.emailVerificationPending) {
        return currentPath == '/verify-email' ? null : '/verify-email';
      }

      if (!isAuthenticated) {
        if (currentPath == '/splash') {
          return '/login';
        }

        return isAuthFlow ? null : '/login';
      }

      if (isAuthenticated && isAuthFlow) {
        return '/';
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
        path: '/verify-email',
        builder: (context, state) => const _VerifyEmailWrapper(),
      ),
      GoRoute(
        path: '/auth-loading',
        builder: (context, state) => const AuthLoadingScreen(),
      ),
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
        path: '/users/:userId',
        builder: (context, state) => PublicProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/create-place',
        builder: (context, state) => const CreatePlaceScreen(),
      ),
      GoRoute(
        path: '/create-event',
        builder: (context, state) => const CreateEventScreen(),
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
      GoRoute(
        path: '/post/:id',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),
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
            routes: [
              GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rankings',
                builder: (_, _) => const RankingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});

class _VerifyEmailWrapper extends ConsumerWidget {
  const _VerifyEmailWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email =
        ref.watch(authProvider.select((value) => value.pendingEmail)) ?? '';
    return EmailVerificationScreen(email: email);
  }
}

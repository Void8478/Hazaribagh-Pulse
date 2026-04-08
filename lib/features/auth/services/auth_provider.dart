import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/supabase_client.dart';

// ---------------------------------------------------------------------------
// Stream of the current Supabase user (null = signed out)
// ---------------------------------------------------------------------------
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref
      .watch(supabaseClientProvider)
      .auth
      .onAuthStateChange
      .map((event) => event.session?.user);
});

// ---------------------------------------------------------------------------
// AuthState — single source of truth for all auth UI states
// ---------------------------------------------------------------------------
class AuthState {
  final bool isLoading;

  /// True during the one-time startup check (app open).
  final bool isInitializing;

  /// Non-null when something went wrong.
  final String? error;

  /// Google/social sign-in: user has a session but no complete profile row yet.
  final bool needsProfileCompletion;

  /// Email signup: account created, waiting for the user to click confirm link.
  final bool emailVerificationPending;

  /// Store the email used during signup so the verification screen can display it.
  final String? pendingEmail;

  /// True when login/signup succeeded AND profile is verified — trigger loading screen.
  final bool readyForApp;

  const AuthState({
    this.isLoading = false,
    this.isInitializing = false,
    this.error,
    this.needsProfileCompletion = false,
    this.emailVerificationPending = false,
    this.pendingEmail,
    this.readyForApp = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitializing,
    String? error,
    bool clearError = false,
    bool? needsProfileCompletion,
    bool? emailVerificationPending,
    String? pendingEmail,
    bool? readyForApp,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearError ? null : (error ?? this.error),
      needsProfileCompletion:
          needsProfileCompletion ?? this.needsProfileCompletion,
      emailVerificationPending:
          emailVerificationPending ?? this.emailVerificationPending,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      readyForApp: readyForApp ?? this.readyForApp,
    );
  }

  @override
  String toString() {
    return 'AuthState('
        'isLoading: $isLoading, '
        'isInitializing: $isInitializing, '
        'error: $error, '
        'needsProfileCompletion: $needsProfileCompletion, '
        'emailVerificationPending: $emailVerificationPending, '
        'pendingEmail: $pendingEmail, '
        'readyForApp: $readyForApp)';
  }
}

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------
class AuthNotifier extends Notifier<AuthState> {
  late final SupabaseClient _supabase;
  late final GoogleSignIn _googleSignIn;

  @override
  AuthState build() {
    _supabase = ref.watch(supabaseClientProvider);
    _googleSignIn = GoogleSignIn();

    debugPrint('🔄 [AuthNotifier] build() — initializing');
    _initializeWithAuthStream();

    return const AuthState(isInitializing: true);
  }

  // ── Startup ──────────────────────────────────────────────────────────────

  /// Waits for the first Supabase auth event on cold start, then decides state.
  Future<void> _initializeWithAuthStream() async {
    try {
      debugPrint('🔄 [AuthNotifier] Awaiting first auth stream event...');

      final event = await _supabase.auth.onAuthStateChange.first.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⚠️ [AuthNotifier] Auth stream timed out — treating as unauthenticated');
          throw TimeoutException('Auth stream timed out');
        },
      );

      final user = event.session?.user;
      debugPrint('🔄 [AuthNotifier] First event — user: ${user?.id ?? 'null'}');

      if (user == null) {
        state = state.copyWith(isInitializing: false);
        return;
      }

      // Check email confirmation status
      if (!_isEmailConfirmed(user)) {
        debugPrint('📧 [AuthNotifier] User email not confirmed on startup');
        state = state.copyWith(
          isInitializing: false,
          emailVerificationPending: true,
          pendingEmail: user.email,
        );
        return;
      }

      await _verifyUserProfile(user, isStartup: true);
    } catch (e) {
      debugPrint('⚠️ [AuthNotifier] Initialization error (non-fatal): $e');
      state = state.copyWith(isInitializing: false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true when the Supabase user has confirmed their email.
  bool _isEmailConfirmed(User user) {
    // For Google OAuth users, email_confirmed_at is always set.
    // For email/password, it is set only after the user clicks the link.
    final confirmedAt = user.emailConfirmedAt;
    return confirmedAt != null;
  }

  /// Checks and upserts a profile row, then signals ready.
  Future<void> _verifyUserProfile(User user, {bool isStartup = false}) async {
    try {
      debugPrint('🔄 [AuthNotifier] Checking profile for ${user.id}');

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              debugPrint('⚠️ [AuthNotifier] Profile fetch timed out');
              throw TimeoutException('Profile fetch timed out');
            },
          );

      if (profile == null) {
        debugPrint('📋 [AuthNotifier] No profile row — needs completion');
        if (isStartup) {
          state = state.copyWith(isInitializing: false, needsProfileCompletion: true);
        } else {
          state = state.copyWith(isLoading: false, needsProfileCompletion: true);
        }
        return;
      }

      final phoneNumber = profile['phone_number'];
      if (phoneNumber == null || phoneNumber.toString().trim().isEmpty) {
        debugPrint('📋 [AuthNotifier] Phone missing — needs completion');
        if (isStartup) {
          state = state.copyWith(isInitializing: false, needsProfileCompletion: true);
        } else {
          state = state.copyWith(isLoading: false, needsProfileCompletion: true);
        }
        return;
      }

      debugPrint('✅ [AuthNotifier] Profile OK — readyForApp');
      if (isStartup) {
        state = state.copyWith(isInitializing: false, readyForApp: true);
      } else {
        state = state.copyWith(isLoading: false, readyForApp: true);
      }
    } catch (e) {
      debugPrint('⚠️ [AuthNotifier] Profile check failed (non-fatal): $e');
      // On failure, allow entry to app — do not block forever.
      if (isStartup) {
        state = state.copyWith(isInitializing: false, readyForApp: true);
      } else {
        state = state.copyWith(isLoading: false, readyForApp: true);
      }
    }
  }

  // ── Google Auth ───────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(OAuthProvider.google);
        return;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Missing Google Auth Token';
      }

      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = res.user;
      if (user != null) {
        await _verifyUserProfile(user);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Google Sign-In failed: ${e.toString()}');
    }
  }

  Future<void> completeGoogleProfile(
      String fullName, String phoneNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not signed in');
        return;
      }

      final uid = user.id;
      final now = DateTime.now().toIso8601String();

      final existing =
          await _supabase.from('profiles').select().eq('id', uid).maybeSingle();
      if (existing == null) {
        await _supabase.from('profiles').insert({
          'id': uid,
          'full_name': fullName,
          'email': user.email ?? '',
          'phone_number': phoneNumber,
          'auth_provider': 'google',
          'avatar_url': user.userMetadata?['avatar_url'] ?? '',
          'created_at': now,
          'updated_at': now,
          'trust_level': 'Newcomer',
          'points': 0,
          'reviews_count': 0,
          'photos_count': 0,
          'saved_place_ids': [],
          'saved_event_ids': [],
        });
      } else {
        await _supabase.from('profiles').update({
          'full_name': fullName,
          'phone_number': phoneNumber,
          'updated_at': now,
        }).eq('id', uid);
      }

      state = state.copyWith(
          isLoading: false, needsProfileCompletion: false, readyForApp: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: 'Failed to complete profile: ${e.toString()}');
    }
  }

  // ── Email Auth ────────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res =
          await _supabase.auth.signInWithPassword(email: email, password: password);

      final user = res.user;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Sign-in failed. Please try again.');
        return;
      }

      if (!_isEmailConfirmed(user)) {
        debugPrint('📧 [AuthNotifier] Login blocked — email not confirmed');
        state = state.copyWith(
          isLoading: false,
          emailVerificationPending: true,
          pendingEmail: email,
        );
        return;
      }

      await _verifyUserProfile(user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }

  Future<void> signUpWithEmail(
      String fullName, String email, String phoneNumber, String password) async {
    state = state.copyWith(
        isLoading: true, clearError: true, emailVerificationPending: false);
    try {
      final res = await _supabase.auth.signUp(email: email, password: password);

      // Try to insert profile row. If RLS blocks unconfirmed users, we catch silently.
      if (res.user != null) {
        final uid = res.user!.id;
        final now = DateTime.now().toIso8601String();
        try {
          await _supabase.from('profiles').insert({
            'id': uid,
            'full_name': fullName,
            'email': email,
            'phone_number': phoneNumber,
            'auth_provider': 'email',
            'avatar_url': '',
            'created_at': now,
            'updated_at': now,
            'trust_level': 'Newcomer',
            'points': 0,
            'reviews_count': 0,
            'photos_count': 0,
            'saved_place_ids': [],
            'saved_event_ids': [],
          });
        } catch (profileErr) {
          debugPrint('⚠️ [AuthNotifier] Profile insert skipped (likely RLS on unconfirmed): $profileErr');
        }
      }

      // session == null → email confirmation required
      if (res.session == null) {
        debugPrint('📧 [AuthNotifier] Signup OK — awaiting email confirmation');
        state = state.copyWith(
          isLoading: false,
          emailVerificationPending: true,
          pendingEmail: email,
        );
        return;
      }

      // session != null → confirmation disabled, user is immediately signed in
      final user = res.user;
      if (user != null) {
        await _verifyUserProfile(user);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred');
    }
  }

  // ── Email Verification ────────────────────────────────────────────────────

  /// Resend the confirmation email.
  Future<void> resendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to resend email. Try again.');
    }
  }

  /// Called when user taps "I've verified" on EmailVerificationScreen.
  /// Refreshes the session and checks confirmation status.
  Future<void> checkEmailVerified() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Refresh the session so we get the latest email_confirmed_at
      await _supabase.auth.refreshSession();

      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
            isLoading: false, error: 'No session. Please log in again.');
        return;
      }

      if (!_isEmailConfirmed(user)) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email not verified yet. Please check your inbox.',
        );
        return;
      }

      debugPrint('✅ [AuthNotifier] Email verified — proceeding to profile check');
      state = state.copyWith(emailVerificationPending: false);
      await _verifyUserProfile(user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Verification check failed. Try again.');
    }
  }

  // ── Auth Loading Screen ───────────────────────────────────────────────────

  /// Called by AuthLoadingScreen when it finishes its setup tasks.
  void markAppReady() {
    state = state.copyWith(readyForApp: false); // reset so it doesn't re-trigger
  }

  // ── Misc ──────────────────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!kIsWeb) await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      // Reset all flags
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Sign out failed: ${e.toString()}');
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user is currently signed in.');

      final uid = user.id;

      // Anonymize reviews
      await _supabase.from('reviews').update({
        'author_name': 'Deleted User',
        'author_image_url': '',
      }).eq('author_id', uid);

      // Delete profile row
      await _supabase.from('profiles').delete().eq('id', uid);

      // Sign out (developer must add a Supabase RPC to fully delete auth.users)
      debugPrint('ℹ️ [AuthNotifier] Implement RPC delete_user for full account removal.');
      await _supabase.auth.signOut();
      if (!kIsWeb) await _googleSignIn.signOut();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: 'An unexpected error occurred: ${e.toString()}');
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

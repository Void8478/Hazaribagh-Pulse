import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref
      .watch(supabaseClientProvider)
      .auth
      .onAuthStateChange
      .map((event) => event.session?.user);
});

class AuthState {
  final bool isLoading;
  final bool isInitializing;
  final String? error;
  final bool needsProfileCompletion;
  final bool emailVerificationPending;
  final String? pendingEmail;
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
}

class AuthNotifier extends Notifier<AuthState> {
  late final SupabaseClient _supabase;
  late final GoogleSignIn _googleSignIn;

  static const Set<String> _profileColumns = {
    'id',
    'full_name',
    'username',
    'bio',
    'avatar_url',
    'location',
    'created_at',
    'updated_at',
  };

  @override
  AuthState build() {
    _supabase = ref.watch(supabaseClientProvider);
    _googleSignIn = GoogleSignIn();
    _initializeWithAuthStream();
    return const AuthState(isInitializing: true);
  }

  Future<void> _initializeWithAuthStream() async {
    try {
      final event = await _supabase.auth.onAuthStateChange.first.timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Auth stream timed out'),
      );

      final user = event.session?.user;
      if (user == null) {
        state = state.copyWith(isInitializing: false);
        return;
      }

      if (!_isEmailConfirmed(user)) {
        state = state.copyWith(
          isInitializing: false,
          emailVerificationPending: true,
          pendingEmail: user.email,
        );
        return;
      }

      await _verifyUserProfile(user, isStartup: true);
    } catch (_) {
      state = state.copyWith(isInitializing: false);
    }
  }

  bool _isEmailConfirmed(User user) => user.emailConfirmedAt != null;

  String? _normalizedString(
    Object? value, {
    bool allowEmpty = false,
  }) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty && !allowEmpty) return null;
    return text;
  }

  Map<String, dynamic> _buildProfileWriteData({
    required User user,
    required String now,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? location,
    bool includeId = false,
    bool includeCreatedAt = false,
  }) {
    final data = <String, dynamic>{};

    void putString(
      String key,
      Object? value, {
      bool allowEmpty = false,
      bool includeEmpty = false,
    }) {
      if (!_profileColumns.contains(key)) return;
      final normalized = _normalizedString(value, allowEmpty: allowEmpty);
      if (normalized != null) {
        data[key] = normalized;
      } else if (includeEmpty) {
        data[key] = '';
      }
    }

    if (includeId) {
      data['id'] = user.id;
    }

    putString(
      'full_name',
      fullName ?? user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
    );
    putString('username', username ?? user.userMetadata?['username']);
    putString(
      'bio',
      bio ?? user.userMetadata?['bio'],
      allowEmpty: true,
      includeEmpty: true,
    );
    putString(
      'avatar_url',
      avatarUrl ?? user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
      allowEmpty: true,
      includeEmpty: true,
    );
    putString(
      'location',
      location ?? user.userMetadata?['location'],
      allowEmpty: true,
      includeEmpty: true,
    );

    if (includeCreatedAt) {
      data['created_at'] = now;
    }
    data['updated_at'] = now;
    return data;
  }

  Future<Map<String, dynamic>> _ensureProfileRow(
    User user, {
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? location,
  }) async {
    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final now = DateTime.now().toIso8601String();

    if (existing == null) {
      final created = await _supabase
          .from('profiles')
          .insert(
            _buildProfileWriteData(
              user: user,
              now: now,
              fullName: fullName,
              username: username,
              bio: bio,
              avatarUrl: avatarUrl,
              location: location,
              includeId: true,
              includeCreatedAt: true,
            ),
          )
          .select()
          .single();
      return Map<String, dynamic>.from(created);
    }

    final updateData = <String, dynamic>{};

    void fillIfMissing(
      String key,
      Object? current,
      Object? next, {
      bool allowEmpty = false,
    }) {
      final currentText = _normalizedString(current, allowEmpty: allowEmpty);
      final nextText = _normalizedString(next, allowEmpty: allowEmpty);
      if (currentText == null && nextText != null) {
        updateData[key] = nextText;
      }
    }

    fillIfMissing(
      'full_name',
      existing['full_name'],
      fullName ?? user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
    );
    fillIfMissing(
      'username',
      existing['username'],
      username ?? user.userMetadata?['username'],
    );
    fillIfMissing(
      'bio',
      existing['bio'],
      bio ?? user.userMetadata?['bio'] ?? '',
      allowEmpty: true,
    );
    fillIfMissing(
      'avatar_url',
      existing['avatar_url'],
      avatarUrl ?? user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'] ?? '',
      allowEmpty: true,
    );
    fillIfMissing(
      'location',
      existing['location'],
      location ?? user.userMetadata?['location'] ?? '',
      allowEmpty: true,
    );

    if (updateData.isNotEmpty) {
      updateData['updated_at'] = now;
      final updated = await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();
      return Map<String, dynamic>.from(updated);
    }

    return Map<String, dynamic>.from(existing);
  }

  Future<void> _verifyUserProfile(User user, {bool isStartup = false}) async {
    try {
      await _ensureProfileRow(user).timeout(
        const Duration(seconds: 6),
        onTimeout: () => throw TimeoutException('Profile fetch timed out'),
      );

      state = state.copyWith(
        isInitializing: isStartup ? false : state.isInitializing,
        isLoading: isStartup ? state.isLoading : false,
        needsProfileCompletion: false,
        readyForApp: true,
      );
    } catch (e) {
      debugPrint('Profile check failed: $e');
      state = state.copyWith(
        isInitializing: isStartup ? false : state.isInitializing,
        isLoading: isStartup ? state.isLoading : false,
        readyForApp: true,
      );
    }
  }

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
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Missing Google auth token');
      }

      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (res.user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      await _verifyUserProfile(res.user!);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google Sign-In failed: $e',
      );
    }
  }

  Future<void> completeGoogleProfile(
    String fullName,
    String phoneNumber,
  ) async {
    return completeProfile(fullName, phoneNumber);
  }

  Future<void> completeProfile(
    String fullName,
    String phoneNumber,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not signed in');
        return;
      }

      final now = DateTime.now().toIso8601String();
      final existing = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final writeData = _buildProfileWriteData(
        user: user,
        now: now,
        fullName: fullName,
        bio: _normalizedString(existing?['bio'], allowEmpty: true) ?? '',
        avatarUrl: _normalizedString(
              existing?['avatar_url'] ??
                  user.userMetadata?['avatar_url'] ??
                  user.userMetadata?['picture'],
              allowEmpty: true,
            ) ??
            '',
        location: _normalizedString(existing?['location'], allowEmpty: true) ?? '',
        includeId: existing == null,
        includeCreatedAt: existing == null,
      );

      if (existing == null) {
        await _supabase.from('profiles').insert(writeData);
      } else {
        await _supabase.from('profiles').update(writeData).eq('id', user.id);
      }

      state = state.copyWith(
        isLoading: false,
        needsProfileCompletion: false,
        readyForApp: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete profile: $e',
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign-in failed. Please try again.',
        );
        return;
      }

      if (!_isEmailConfirmed(user)) {
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
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> signUpWithEmail(
    String fullName,
    String email,
    String phoneNumber,
    String password,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      emailVerificationPending: false,
    );

    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'bio': '',
          'location': '',
          'avatar_url': '',
        },
      );

      if (res.user != null) {
        try {
          await _ensureProfileRow(
            res.user!,
            fullName: fullName,
            bio: '',
            avatarUrl: '',
            location: '',
          );
        } catch (profileErr) {
          debugPrint('Profile insert skipped: $profileErr');
        }
      }

      if (res.session == null) {
        state = state.copyWith(
          isLoading: false,
          emailVerificationPending: true,
          pendingEmail: email,
        );
        return;
      }

      if (res.user != null) {
        await _verifyUserProfile(res.user!);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to resend email. Try again.',
      );
    }
  }

  Future<void> checkEmailVerified() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.refreshSession();

      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No session. Please log in again.',
        );
        return;
      }

      if (!_isEmailConfirmed(user)) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email not verified yet. Please check your inbox.',
        );
        return;
      }

      state = state.copyWith(emailVerificationPending: false);
      await _verifyUserProfile(user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification check failed. Try again.',
      );
    }
  }

  void markAppReady() {
    state = state.copyWith(readyForApp: false);
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
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
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign out failed: $e',
      );
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user is currently signed in.');

      final uid = user.id;

      await _supabase.from('profiles').delete().eq('id', uid);

      await _supabase.auth.signOut();
      if (!kIsWeb) await _googleSignIn.signOut();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);

  return Stream<User?>.multi((controller) {
    User? lastUser = supabase.auth.currentUser;
    controller.add(lastUser);

    final subscription = supabase.auth.onAuthStateChange.listen((event) {
      final nextUser = event.session?.user;
      final didChange =
          lastUser?.id != nextUser?.id ||
          lastUser?.emailConfirmedAt != nextUser?.emailConfirmedAt;

      if (didChange) {
        lastUser = nextUser;
        controller.add(nextUser);
      }
    });

    controller.onCancel = () {
      subscription.cancel();
    };
  });
});

class StartupMinimumSplashDurationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void reset() {
    state = false;
  }

  void complete() {
    state = true;
  }
}

final startupMinimumSplashDurationProvider =
    NotifierProvider<StartupMinimumSplashDurationNotifier, bool>(
  StartupMinimumSplashDurationNotifier.new,
);

class AuthState {
  final bool isLoading;
  final bool isInitializing;
  final bool isAuthenticated;
  final bool isSigningOut;
  final bool isDeletingAccount;
  final User? user;
  final Map<String, dynamic>? profile;
  final String? error;
  final String? initializationError;
  final bool needsProfileCompletion;
  final bool emailVerificationPending;
  final String? pendingEmail;
  final bool readyForApp;

  const AuthState({
    this.isLoading = false,
    this.isInitializing = false,
    this.isAuthenticated = false,
    this.isSigningOut = false,
    this.isDeletingAccount = false,
    this.user,
    this.profile,
    this.error,
    this.initializationError,
    this.needsProfileCompletion = false,
    this.emailVerificationPending = false,
    this.pendingEmail,
    this.readyForApp = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitializing,
    bool? isAuthenticated,
    bool? isSigningOut,
    bool? isDeletingAccount,
    User? user,
    Map<String, dynamic>? profile,
    String? error,
    String? initializationError,
    bool clearError = false,
    bool clearInitializationError = false,
    bool clearProfile = false,
    bool? needsProfileCompletion,
    bool? emailVerificationPending,
    String? pendingEmail,
    bool? readyForApp,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      user: user ?? this.user,
      profile: clearProfile ? null : (profile ?? this.profile),
      error: clearError ? null : (error ?? this.error),
      initializationError: clearInitializationError
          ? null
          : (initializationError ?? this.initializationError),
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
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<dynamic>? _authStateSubscription;
  Future<void>? _initializationFuture;
  Future<void>? _activeResolutionFuture;
  String? _activeResolutionUserId;
  String? _profileCheckUserId;
  bool _startupRetriedOnce = false;
  int _bootstrapRunId = 0;
  bool _startupRequested = false;

  static const Duration _bootstrapTimeout = Duration(seconds: 8);
  static const Duration _signOutTimeout = Duration(seconds: 10);
  static const Duration _deleteTimeout = Duration(seconds: 15);

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
    _logStep('bootstrap listener attached');
    _authStateSubscription ??= _supabase.auth.onAuthStateChange.listen((
      authState,
    ) {
      final event = authState.event;
      final session = authState.session;
      _logStep(
        'auth transition: $event, hasSession=${session != null}, userId=${session?.user.id}',
      );

      if (event == AuthChangeEvent.signedOut || session?.user == null) {
        _logStep('navigating to login: signed out');
        _logStep('loading finished: signed out');
        _resetToSignedOutState();
        return;
      }

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.initialSession) {
        unawaited(_resolveSession(session, isStartup: false));
      }
    });

    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });

    _logStep('waiting for startup trigger');
    return const AuthState(isInitializing: true);
  }

  void _resetToSignedOutState() {
    _profileCheckUserId = null;
    _activeResolutionFuture = null;
    _activeResolutionUserId = null;
    state = const AuthState();
  }

  bool _isSessionExpiredMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('session expired') ||
        lower.contains('log in again') ||
        lower.contains('login again');
  }

  bool get _hasLocalSession =>
      _supabase.auth.currentSession != null || _supabase.auth.currentUser != null;

  String _stringifyError(Object? value) {
    if (value == null) return '';
    if (value is Map<String, dynamic>) {
      for (final key in const ['message', 'error', 'details', 'description']) {
        final candidate = value[key]?.toString().trim() ?? '';
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }
    return value.toString().trim();
  }

  String _friendlyMessage(
    Object error, {
    required String fallback,
  }) {
    final raw = error is AuthException
        ? error.message
        : error is FunctionException
            ? _stringifyError(error.details).isNotEmpty
                  ? _stringifyError(error.details)
                  : _stringifyError(error.reasonPhrase)
            : _stringifyError(error);

    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return fallback;
    }

    final lower = normalized.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection closed') ||
        lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('clientexception')) {
      return 'No internet connection. Please reconnect and try again.';
    }

    if (lower.contains('invalid jwt') ||
        lower.contains('jwt expired') ||
        lower.contains('refresh token') ||
        lower.contains('session') && lower.contains('expired')) {
      return 'Your session expired. Please log in again.';
    }

    if (lower.contains('user not found') ||
        lower.contains('unauthorized user') ||
        lower.contains('missing authorization header')) {
      return 'Your session expired. Please log in again.';
    }

    if (lower.contains('duplicate key') ||
        lower.contains('profiles_username_key') ||
        lower.contains('already exists')) {
      return 'That username is already taken. Please choose a different one.';
    }

    return normalized;
  }

  Future<void> startBootstrapIfNeeded() {
    _logStep('startup triggered');
    _startupRequested = true;
    return _initializeAuthState();
  }

  Future<void> _initializeAuthState({bool force = false}) async {
    if (!force && _initializationFuture != null) {
      _logStep('bootstrap already running, joining existing future');
      return _initializationFuture!;
    }

    if (!force && !_startupRequested) {
      _logStep('bootstrap skipped until startup trigger');
      return;
    }

    _startupRetriedOnce = false;
    final runId = ++_bootstrapRunId;
    _logStep('startup began [run=$runId]');
    final future = _runBootstrap(runId);
    _initializationFuture = future;

    try {
      await future;
    } finally {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    }
  }

  Future<void> _runBootstrap(int runId) async {
    try {
      await _performBootstrap(runId).timeout(
        _bootstrapTimeout,
        onTimeout: () async {
          _logStep('bootstrap timeout [run=$runId]');
          throw TimeoutException('Bootstrap timed out');
        },
      );
    } on TimeoutException catch (e) {
      _logStep('bootstrap error [run=$runId]: $e');
      final user = _supabase.auth.currentUser;
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: user != null,
        user: user,
        initializationError:
            'Startup took too long. Please retry once your connection is stable.',
      );
      _logStep('loading finished: bootstrap timeout fallback');
    } catch (e) {
      _logStep('bootstrap error [run=$runId]: $e');
      final user = _supabase.auth.currentUser;
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: user != null,
        user: user,
        initializationError:
            'We could not finish starting the app. Please try again.',
      );
      _logStep('loading finished: bootstrap error fallback');
    }
  }

  Future<void> _performBootstrap(int runId) async {
    final session = _supabase.auth.currentSession;
    final user = session?.user;

    if (user == null) {
      _logStep('no session found [run=$runId], navigating to login');
      _logStep('loading finished: no session');
      state = const AuthState();
      return;
    }

    _logStep('session found [run=$runId], userId=${user.id}');
    await _resolveSession(session, isStartup: true);
  }

  Future<void> _resolveSession(Session? session, {required bool isStartup}) async {
    final user = session?.user;

    if (user == null) {
      _logStep('resolve session: no session, navigating to login');
      state = const AuthState();
      return;
    }

    if (_activeResolutionUserId == user.id && _activeResolutionFuture != null) {
      _logStep('resolve session skipped, already resolving userId=${user.id}');
      return _activeResolutionFuture!;
    }

    final future = _resolveSessionInternal(user, isStartup: isStartup);
    _activeResolutionUserId = user.id;
    _activeResolutionFuture = future;

    try {
      await future;
    } finally {
      if (identical(_activeResolutionFuture, future)) {
        _activeResolutionFuture = null;
        _activeResolutionUserId = null;
      }
    }
  }

  Future<void> _resolveSessionInternal(
    User user, {
    required bool isStartup,
  }) async {
    _logStep(
      '${isStartup ? 'startup' : 'transition'} resolve session for userId=${user.id}',
    );
    state = state.copyWith(
      isInitializing: isStartup,
      isLoading: !isStartup,
      isAuthenticated: true,
      isSigningOut: false,
      isDeletingAccount: false,
      user: user,
      clearError: true,
      clearInitializationError: true,
      emailVerificationPending: false,
      pendingEmail: user.email,
      readyForApp: false,
    );

    if (!_isEmailConfirmed(user)) {
      _logStep('email not verified for userId=${user.id}');
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: false,
        isSigningOut: false,
        isDeletingAccount: false,
        emailVerificationPending: true,
        pendingEmail: user.email,
      );
      return;
    }

    await _verifyUserProfile(user, isStartup: isStartup);
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
    _logStep('fetching profile for userId=${user.id}');
    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final now = DateTime.now().toIso8601String();

    if (existing == null) {
      _logStep('profile missing for userId=${user.id}, creating profile');
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
      _logStep('profile created for userId=${user.id}');
      return Map<String, dynamic>.from(created);
    }

    _logStep('profile found for userId=${user.id}');

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
      _logStep('profile patching missing fields for userId=${user.id}');
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

  Future<void> _verifyUserProfile(
    User user, {
    bool isStartup = false,
    int attempt = 0,
  }) async {
    if (_profileCheckUserId == user.id) {
      return;
    }

    _profileCheckUserId = user.id;

    try {
      final profile = await _ensureProfileRow(user).timeout(
        const Duration(seconds: 7),
        onTimeout: () => throw TimeoutException('Profile fetch timed out'),
      );
      _logStep('profile ready for userId=${user.id}, navigating to home');

      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: true,
        isSigningOut: false,
        isDeletingAccount: false,
        user: user,
        profile: profile,
        clearInitializationError: true,
        needsProfileCompletion: false,
        emailVerificationPending: false,
        pendingEmail: user.email,
        readyForApp: false,
      );
      _startupRetriedOnce = false;
      _logStep('loading finished: startup success');
    } catch (e) {
      _logStep('profile bootstrap error for userId=${user.id}: $e');

      if (isStartup && !_startupRetriedOnce && attempt == 0) {
        _startupRetriedOnce = true;
        _logStep('bootstrap retrying profile fetch once for userId=${user.id}');
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (_profileCheckUserId == user.id) {
          _profileCheckUserId = null;
        }
        return _verifyUserProfile(user, isStartup: true, attempt: 1);
      }

      final fallbackProfile = _buildProfileWriteData(
        user: user,
        now: DateTime.now().toIso8601String(),
        includeId: true,
        includeCreatedAt: true,
      );

      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: true,
        isSigningOut: false,
        isDeletingAccount: false,
        user: user,
        profile: fallbackProfile,
        clearInitializationError: true,
        readyForApp: false,
      );
      _logStep('loading finished: profile bootstrap fallback with local profile');
    } finally {
      if (_profileCheckUserId == user.id) {
        _profileCheckUserId = null;
      }
    }
  }

  void _logStep(String message) {
    if (kDebugMode) {
      debugPrint('[AuthBootstrap] $message');
    }
  }

  Future<void> signInWithGoogle() async {
    ref.read(startupMinimumSplashDurationProvider.notifier).reset();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(OAuthProvider.google);
        return;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
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
        readyForApp: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete profile: $e',
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    ref.read(startupMinimumSplashDurationProvider.notifier).reset();
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
        isAuthenticated: false,
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
    ref.read(startupMinimumSplashDurationProvider.notifier).reset();
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
          if (kDebugMode) {
            debugPrint('Profile insert skipped: $profileErr');
          }
        }
      }

      if (res.session == null) {
      state = state.copyWith(
        isLoading: false,
        emailVerificationPending: true,
        isAuthenticated: false,
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
    state = state.copyWith(readyForApp: true);
  }

  Future<void> retryInitialization() {
    _logStep('retry function called');
    _startupRequested = true;
    return _initializeAuthState(force: true);
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
    if (state.isSigningOut) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isSigningOut: true,
      isDeletingAccount: false,
      clearError: true,
    );
    try {
      await _supabase.auth.signOut().timeout(_signOutTimeout);
      _resetToSignedOutState();
    } catch (e) {
      final message = _friendlyMessage(
        e,
        fallback: 'We could not log you out right now. Please try again.',
      );

      if (!_hasLocalSession) {
        _resetToSignedOutState();
        return;
      }

      if (_isSessionExpiredMessage(message)) {
        state = AuthState(error: message);
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isSigningOut: false,
        error: message,
      );
    }
  }

  Future<bool> deleteAccount() async {
    if (state.isDeletingAccount) {
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      isSigningOut: false,
      isDeletingAccount: true,
      clearError: true,
    );
    try {
      final user = _supabase.auth.currentUser;
      final session = _supabase.auth.currentSession;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      if (session == null) {
        throw Exception('Your session expired. Please log in again.');
      }

      _logStep('delete account requested for userId=${user.id}');
      await _supabase.functions
          .invoke(
            'delete-account',
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
            },
          )
          .timeout(_deleteTimeout);
      _logStep('delete account edge function succeeded for userId=${user.id}');

      try {
        await _supabase.auth.signOut();
      } catch (signOutError) {
        _logStep(
          'local sign out after account deletion returned: $signOutError',
        );
      }

      _logStep('navigating to login: account permanently deleted');
      _resetToSignedOutState();
      return true;
    } on FunctionException catch (e) {
      final message = _friendlyMessage(
        e,
        fallback: 'Failed to permanently delete your account.',
      );
      if (_isSessionExpiredMessage(message)) {
        state = AuthState(error: message);
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isDeletingAccount: false,
        error: message,
      );
    } catch (e) {
      final message = _friendlyMessage(
        e,
        fallback: 'Failed to permanently delete your account.',
      );

      if (!_hasLocalSession) {
        _resetToSignedOutState();
        return true;
      }

      if (_isSessionExpiredMessage(message)) {
        state = AuthState(error: message);
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isDeletingAccount: false,
        error: message,
      );
    }

    return false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

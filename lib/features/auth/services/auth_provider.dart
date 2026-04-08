import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// A provider to instantly detect if the user is authenticated
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AuthState {
  final bool isLoading;
  final bool isInitializing; // Wait lock for async fetch of Google/Email profile integrity
  final String? error;
  final bool needsProfileCompletion; // Triggered if user lacks phone numbers on Google Auth sign ins

  AuthState({
    this.isLoading = false,
    this.isInitializing = false,
    this.error,
    this.needsProfileCompletion = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitializing,
    String? error,
    bool clearError = false,
    bool? needsProfileCompletion,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearError ? null : (error ?? this.error),
      needsProfileCompletion: needsProfileCompletion ?? this.needsProfileCompletion,
    );
  }

  @override
  String toString() {
    return 'AuthState(isLoading: $isLoading, isInitializing: $isInitializing, '
           'error: $error, needsProfileCompletion: $needsProfileCompletion)';
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;

  @override
  AuthState build() {
    _auth = ref.watch(firebaseAuthProvider);
    _googleSignIn = GoogleSignIn();
    
    debugPrint('🔄 [AuthNotifier] build() called — starting initialization');
    
    // Listen to auth state changes and trigger profile verification
    // This replaces the old synchronous currentUser check which caused the race condition
    _initializeWithAuthStream();

    return AuthState(isInitializing: true);
  }

  /// Waits for the FIRST auth state emission from Firebase, then verifies the profile.
  /// This fixes the race condition where currentUser was null before Firebase restored the session.
  Future<void> _initializeWithAuthStream() async {
    try {
      debugPrint('🔄 [AuthNotifier] Waiting for first auth state emission...');
      
      // Wait for the first auth state event with a timeout
      // This ensures we don't wait forever if Firebase auth stream is delayed
      final user = await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⚠️ [AuthNotifier] Auth stream timed out after 8s — treating as unauthenticated');
          return null;
        },
      );
      
      debugPrint('🔄 [AuthNotifier] Auth state received — user: ${user?.uid ?? 'null'}');
      
      if (user == null) {
        // No user session — release the lock, router will redirect to onboarding
        debugPrint('✅ [AuthNotifier] No user session — initialization complete');
        state = state.copyWith(isInitializing: false);
        return;
      }

      // User exists — verify their Firestore profile with a timeout
      await _verifyUserProfile(user);
    } catch (e) {
      debugPrint('⚠️ [AuthNotifier] Initialization error (non-fatal): $e');
      // Always release the lock on error — never leave the app stuck
      state = state.copyWith(isInitializing: false);
    }
  }

  /// Checks if the user has a complete Firestore profile document.
  /// Has a timeout so slow network never blocks startup forever.
  Future<void> _verifyUserProfile(User user) async {
    try {
      debugPrint('🔄 [AuthNotifier] Fetching profile for user: ${user.uid}');
      
      // Timeout the Firestore fetch — if network is slow, don't hang forever
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              debugPrint('⚠️ [AuthNotifier] Firestore profile fetch timed out after 6s');
              throw TimeoutException('Profile fetch timed out');
            },
          );

      if (!doc.exists) {
        debugPrint('📋 [AuthNotifier] Profile doc missing — needs profile completion');
        state = state.copyWith(isInitializing: false, needsProfileCompletion: true);
        return;
      }

      final data = doc.data()!;
      if (data['phoneNumber'] == null || data['phoneNumber'].toString().trim().isEmpty) {
        debugPrint('📋 [AuthNotifier] Phone number missing — needs profile completion');
        state = state.copyWith(isInitializing: false, needsProfileCompletion: true);
        return;
      }

      // Profile is complete
      debugPrint('✅ [AuthNotifier] Profile verified — initialization complete');
      state = state.copyWith(isInitializing: false, needsProfileCompletion: false);
    } catch (e) {
      debugPrint('⚠️ [AuthNotifier] Profile verification failed (non-fatal): $e');
      // On any error (timeout, network, permission), release the lock
      // Let the user through — profile screen handles missing data gracefully
      state = state.copyWith(isInitializing: false, needsProfileCompletion: false);
    }
  }

  // ---- GOOGLE AUTH ----
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final GoogleAuthProvider webProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(webProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          state = state.copyWith(isLoading: false);
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }
      
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Need to complete profile
          state = state.copyWith(isLoading: false, needsProfileCompletion: true);
          return;
        } else {
          final data = doc.data()!;
          if (data['phoneNumber'] == null || data['phoneNumber'].toString().isEmpty) {
            // Missing phone number
            state = state.copyWith(isLoading: false, needsProfileCompletion: true);
            return;
          }
        }
      }

      state = state.copyWith(isLoading: false, needsProfileCompletion: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google Sign-In failed: ${e.toString()}');
    }
  }

  Future<void> completeGoogleProfile(String fullName, String phoneNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not signed in');
        return;
      }
      
      final uid = user.uid;
      final now = DateTime.now();
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) {
        final userModel = UserModel(
          id: uid,
          fullName: fullName,
          email: user.email ?? '',
          phoneNumber: phoneNumber,
          authProvider: 'google',
          avatarUrl: user.photoURL ?? '',
          createdAt: now,
          updatedAt: now,
          trustLevel: 'Newcomer',
          points: 0,
          reviewsCount: 0,
          photosCount: 0,
          savedPlaceIds: [],
          savedEventIds: [],
        );
        await FirebaseFirestore.instance.collection('users').doc(uid).set(userModel.toMap());
      } else {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'updatedAt': Timestamp.fromDate(now),
        });
      }
      
      state = state.copyWith(isLoading: false, needsProfileCompletion: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to complete profile: ${e.toString()}');
    }
  }

  // ---- EMAIL AUTH ----
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Login failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }

  Future<void> signUpWithEmail(String fullName, String email, String phoneNumber, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final now = DateTime.now();
        
        final userModel = UserModel(
          id: uid,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          authProvider: 'email',
          avatarUrl: '',
          createdAt: now,
          updatedAt: now,
          trustLevel: 'Newcomer',
          points: 0,
          reviewsCount: 0,
          photosCount: 0,
          savedPlaceIds: [],
          savedEventIds: [],
        );
        
        await FirebaseFirestore.instance.collection('users').doc(uid).set(userModel.toMap());
      }
      
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Sign up failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Password reset failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }

  // ---- GENERAL ----
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Sign out failed: ${e.toString()}');
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No user is currently signed in.");

      final uid = user.uid;

      // 1. Delete associated identity record in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // 2. Anonymize authored reviews so they gracefully fallback to "Deleted User" without breaking counts
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('authorId', isEqualTo: uid)
          .get();
          
      if (reviewsSnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in reviewsSnapshot.docs) {
          batch.update(doc.reference, {
            'authorName': 'Deleted User',
            'authorImageUrl': '',
          });
        }
        await batch.commit();
      }

      // 3. Erase the Firebase Auth user correctly
      await user.delete();
      
      // 4. Clear Google SDK dependencies matching signOut
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      // Catch specific reauth errors to bounce user out cleanly.
      if (e.code == 'requires-recent-login') {
        // Log out immediately so the router tosses them to onboarding/login
        if (!kIsWeb) {
          await _googleSignIn.signOut();
        }
        await _auth.signOut();
        state = state.copyWith(
          isLoading: false, 
          error: 'requires-recent-login'
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to delete account: ${e.message}');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred: ${e.toString()}');
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

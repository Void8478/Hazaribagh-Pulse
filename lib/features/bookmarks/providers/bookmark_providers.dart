import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/user_model.dart';
import '../../../../models/place_model.dart';
import '../../../../models/event_model.dart';
import '../services/firestore_bookmark_service.dart';
import '../repositories/bookmark_repository.dart';
import '../../auth/services/auth_provider.dart';
import '../../../core/utils/mock_data.dart';

final bookmarkServiceProvider = Provider<FirestoreBookmarkService>((ref) {
  return FirestoreBookmarkService();
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final service = ref.watch(bookmarkServiceProvider);
  return BookmarkRepository(service);
});

// Stream the current user's profile natively from Firestore
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final firebaseUser = ref.watch(authStateChangesProvider).value;
  if (firebaseUser == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(firebaseUser.uid)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  });
});

// Fetch full Place objects based on saved place IDs
final savedPlacesProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final userProfile = await ref.watch(userProfileProvider.future);
  if (userProfile == null || userProfile.savedPlaceIds.isEmpty) {
    return [];
  }

  final chunk = userProfile.savedPlaceIds.take(10).toList();
  
  final snapshot = await FirebaseFirestore.instance
      .collection('places')
      .where(FieldPath.documentId, whereIn: chunk)
      .get();
      
  return snapshot.docs.map((doc) => PlaceModel.fromFirestore(doc)).toList();
});

// Fetch saved events — tries Firestore first, falls back to mock data
final savedEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final userProfile = await ref.watch(userProfileProvider.future);
  if (userProfile == null || userProfile.savedEventIds.isEmpty) {
    return [];
  }

  final savedIds = userProfile.savedEventIds;

  // Try Firestore first
  try {
    final chunk = savedIds.take(10).toList();
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where(FieldPath.documentId, whereIn: chunk)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    }
  } catch (_) {
    // Firestore events collection may not exist yet — fall through to mock
  }

  // Fallback: filter mock events by saved IDs
  return MockData.mockEvents
      .where((e) => savedIds.contains(e.id))
      .toList();
});

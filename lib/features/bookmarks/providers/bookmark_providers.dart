import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/user_model.dart';
import '../../../../models/place_model.dart';
import '../services/firestore_bookmark_service.dart';
import '../repositories/bookmark_repository.dart';
import '../../auth/services/auth_provider.dart';

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

  // Chunking limits up to 10 whereIn elements in Firestore
  // For safety, let's grab chunk 1 here, assuming simple cases for this prototype.
  final chunk = userProfile.savedPlaceIds.take(10).toList(); 
  
  final snapshot = await FirebaseFirestore.instance
      .collection('places')
      .where(FieldPath.documentId, whereIn: chunk)
      .get();
      
  return snapshot.docs.map((doc) => PlaceModel.fromFirestore(doc)).toList();
});

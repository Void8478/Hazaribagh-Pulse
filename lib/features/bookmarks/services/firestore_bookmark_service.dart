import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleSavedPlace(String userId, String placeId, bool isSaving) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      if (isSaving) {
        await userRef.update({
          'savedPlaceIds': FieldValue.arrayUnion([placeId])
        });
      } else {
        await userRef.update({
          'savedPlaceIds': FieldValue.arrayRemove([placeId])
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle saved place: $e');
    }
  }

  // Similar logic can be applied to Events if needed: toggleSavedEvent
}

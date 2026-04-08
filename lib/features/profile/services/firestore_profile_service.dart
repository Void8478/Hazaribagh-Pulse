import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/review_model.dart';

class FirestoreProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('authorId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  /// Update user profile fields in Firestore
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Delete all user-specific data (profile doc, saved data)
  /// Reviews are NOT deleted — they display as "Deleted User"
  Future<void> deleteUserData(String userId) async {
    try {
      // Update all reviews by this user to show "Deleted User"
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('authorId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in reviewsSnapshot.docs) {
        batch.update(doc.reference, {
          'authorName': 'Deleted User',
          'authorImageUrl': '',
        });
      }

      // Delete the user profile document
      batch.delete(_firestore.collection('users').doc(userId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}

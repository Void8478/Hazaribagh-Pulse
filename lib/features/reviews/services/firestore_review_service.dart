import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/review_model.dart';

class FirestoreReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ReviewModel>> getReviewsByListingId(String listingId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('listingId', isEqualTo: listingId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Add the review to the reviews collection
      final reviewRef = _firestore.collection('reviews').doc();
      batch.set(reviewRef, review.toMap());
      
      // 2. Increment the user's reviewsCount
      final userRef = _firestore.collection('users').doc(review.authorId);
      batch.update(userRef, {
        'reviewsCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }
}

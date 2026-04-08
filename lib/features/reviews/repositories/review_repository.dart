import '../../../../models/review_model.dart';
import '../services/supabase_review_service.dart';

class ReviewRepository {
  final SupabaseReviewService _service;

  ReviewRepository(this._service);

  Future<List<ReviewModel>> fetchReviewsByListingId(String listingId) {
    return _service.getReviewsByListingId(listingId);
  }

  Future<void> saveReview(ReviewModel review) {
    return _service.submitReview(review);
  }
}

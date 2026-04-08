import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hazaribagh_pulse/models/review_model.dart';

class SupabaseReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  Future<List<ReviewModel>> getReviewsByListingId(String listingId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, profiles(id, full_name, username, avatar_url)')
          .eq('listing_id', _normalizedId(listingId))
          .order('created_at', ascending: false);
      return (response as List)
          .map((data) => ReviewModel.fromJson(Map<String, dynamic>.from(data as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('auth_required');
    }

    try {
      final payload = review.toMap()
        ..['listing_id'] = _normalizedId(review.listingId)
        ..['user_id'] = user.id
        ..remove('author_id')
        ..remove('author_name')
        ..remove('author_image_url')
        ..remove('timestamp');

      await _supabase.from('reviews').insert(payload);
      await _refreshListingStats(review.listingId);
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<void> _refreshListingStats(String listingId) async {
    final listingIdValue = _normalizedId(listingId);
    final response = await _supabase
        .from('reviews')
        .select('rating')
        .eq('listing_id', listingIdValue);

    final reviews = (response as List)
        .map((item) => (item as Map<String, dynamic>)['rating'])
        .where((rating) => rating != null)
        .map((rating) => (rating as num).toDouble())
        .toList();

    final reviewCount = reviews.length;
    final averageRating = reviewCount == 0
        ? 0.0
        : reviews.reduce((value, element) => value + element) / reviewCount;

    await _supabase.from('listings').update({
      'rating': double.parse(averageRating.toStringAsFixed(1)),
      'review_count': reviewCount,
    }).eq('id', listingIdValue);
  }
}

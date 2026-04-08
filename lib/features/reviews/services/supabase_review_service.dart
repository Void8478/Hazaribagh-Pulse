import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/review_model.dart';

class SupabaseReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ReviewModel>> getReviewsByListingId(String listingId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('reviews')
          .select()
          .eq('listing_id', listingId)
          .order('timestamp', ascending: false);
      return response.map((data) => ReviewModel.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    try {
      // 1. Add the review to the reviews collection
      await _supabase.from('reviews').insert(review.toMap());
      
      // 2. Increment the user's reviewsCount in profiles (Optional step if tracked in profiles)
      // Note: Assuming Supabase trigger or RPC here. For now, doing a client-side fetch & update approach
      // or RPC for simplicity if you want it reliable:
      // await _supabase.rpc('increment_review_count', params: {'user_id': review.authorId});
      
      // Alternatively, we can just fetch and plus one:
      final userResponse = await _supabase.from('profiles').select('reviews_count').eq('id', review.authorId).maybeSingle();
      if (userResponse != null) {
        final currentCount = userResponse['reviews_count'] ?? 0;
        await _supabase.from('profiles').update({'reviews_count': currentCount + 1}).eq('id', review.authorId);
      }
      
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }
}

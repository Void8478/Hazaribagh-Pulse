import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/review_model.dart';
import '../services/supabase_review_service.dart';
import '../repositories/review_repository.dart';

final reviewServiceProvider = Provider<SupabaseReviewService>((ref) {
  return SupabaseReviewService();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final service = ref.watch(reviewServiceProvider);
  return ReviewRepository(service);
});

final listingReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((ref, listingId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.fetchReviewsByListingId(listingId);
});

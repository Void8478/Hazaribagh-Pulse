import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_profile_service.dart';
import '../repositories/profile_repository.dart';
import '../../../../models/review_model.dart';


final profileServiceProvider = Provider<FirestoreProfileService>((ref) {
  return FirestoreProfileService();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileRepository(service);
});

// Fetches the globally authenticated user's reviews dynamically
final userReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((ref, userId) async {
  return ref.watch(profileRepositoryProvider).getUserReviews(userId);
});

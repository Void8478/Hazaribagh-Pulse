import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazaribagh_pulse/models/review_model.dart';
import 'package:hazaribagh_pulse/models/user_model.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/services/auth_provider.dart';
import '../services/supabase_profile_service.dart';
import '../repositories/profile_repository.dart';
final profileServiceProvider = Provider<SupabaseProfileService>((ref) {
  return SupabaseProfileService();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileRepository(service);
});

// Fetches the globally authenticated user's reviews dynamically
final userReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((ref, userId) async {
  return ref.watch(profileRepositoryProvider).getUserReviews(userId);
});

// Stream the current user's profile natively from Supabase
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authProvider.select((value) => value.user));
  if (user == null) {
    return Stream.value(null);
  }

  final supabase = ref.watch(supabaseClientProvider);
  final service = ref.watch(profileServiceProvider);

  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .asyncMap((list) async {
        if (list.isNotEmpty) {
          return UserModel.fromProfile(
            Map<String, dynamic>.from(list.first),
            email: user.email ?? '',
          );
        }

        return service.ensureProfileForCurrentUser();
      });
});

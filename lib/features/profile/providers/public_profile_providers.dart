import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../../models/post_model.dart';
import '../../../models/user_model.dart';
import '../../events/providers/event_providers.dart';
import '../../listings/providers/listing_providers.dart';
import '../../posts/providers/post_providers.dart';
import '../providers/profile_providers.dart';

final publicUserProfileProvider = FutureProvider.family<UserModel, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserProfile(userId);
});

final publicUserPostsProvider = FutureProvider.family<List<PostModel>, String>((
  ref,
  userId,
) async {
  final service = ref.watch(postServiceProvider);
  return service.getPostsByUserId(userId);
});

final publicUserListingsProvider = FutureProvider.family<List<PlaceModel>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchListingsByUserId(userId);
});

final publicUserEventsProvider = FutureProvider.family<List<EventModel>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.fetchEventsByUserId(userId);
});

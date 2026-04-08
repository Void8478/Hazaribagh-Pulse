import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../events/providers/event_providers.dart';
import '../../listings/providers/listing_providers.dart';
import '../../posts/providers/post_providers.dart';
import '../../../models/post_model.dart';

final homeTrendingListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchTrendingListings(limit: 8);
});

final homeTopRatedListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchTopRatedListings(limit: 8);
});

final homeHiddenGemListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchHiddenGemListings(limit: 8);
});

final homeUpcomingEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.fetchUpcomingEvents(limit: 6);
});

final homeRecentPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.watch(postServiceProvider).getRecentPosts(limit: 6);
});

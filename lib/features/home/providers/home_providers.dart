import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../events/providers/event_providers.dart';
import '../../listings/providers/listing_providers.dart';
import '../../posts/providers/post_providers.dart';
import '../../../models/post_model.dart';

class HomeCategorySection {
  const HomeCategorySection({
    required this.category,
    required this.listings,
  });

  final CategoryModel category;
  final List<PlaceModel> listings;
}

final homeFeaturedListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchFeaturedListings(limit: 8);
});

final homeRankedListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchRankedListings(limit: 8);
});

final homeCategorySectionsProvider =
    FutureProvider<List<HomeCategorySection>>((ref) async {
  final categories = await ref.watch(allCategoriesProvider.future);
  final listings = await ref.watch(allListingsProvider.future);
  final sections = <HomeCategorySection>[];

  for (final category in categories) {
    final matchingListings = listings
        .where((listing) => listing.categoryId == category.id)
        .take(6)
        .toList();
    if (matchingListings.isEmpty) {
      continue;
    }
    sections.add(HomeCategorySection(category: category, listings: matchingListings));
    if (sections.length == 3) {
      break;
    }
  }

  return sections;
});

final homeUpcomingEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.fetchUpcomingEvents(limit: 6);
});

final homeRecentPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.watch(postServiceProvider).getRecentPosts(limit: 6);
});

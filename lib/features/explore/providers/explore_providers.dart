import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/place_model.dart';
import '../../listings/providers/listing_providers.dart';

// Sort mode
enum ExploreSortMode { rating, reviews, nameAZ }

// Search query state
class ExploreSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
}

final exploreSearchQueryProvider = NotifierProvider<ExploreSearchQueryNotifier, String>(() {
  return ExploreSearchQueryNotifier();
});

// Selected category filter (null = all)
class ExploreCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? category) => state = category;
}

final exploreCategoryProvider = NotifierProvider<ExploreCategoryNotifier, String?>(() {
  return ExploreCategoryNotifier();
});

// Sort mode
class ExploreSortNotifier extends Notifier<ExploreSortMode> {
  @override
  ExploreSortMode build() => ExploreSortMode.rating;
  void set(ExploreSortMode mode) => state = mode;
}

final exploreSortProvider = NotifierProvider<ExploreSortNotifier, ExploreSortMode>(() {
  return ExploreSortNotifier();
});

// Combined filtered + sorted listings
final filteredListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final allListings = await ref.watch(allListingsProvider.future);
  final query = ref.watch(exploreSearchQueryProvider).toLowerCase();
  final category = ref.watch(exploreCategoryProvider);
  final sortMode = ref.watch(exploreSortProvider);

  // Filter
  var filtered = allListings.where((place) {
    final matchesCategory = category == null || place.category == category;
    final matchesSearch = query.isEmpty ||
        place.name.toLowerCase().contains(query) ||
        place.category.toLowerCase().contains(query) ||
        place.address.toLowerCase().contains(query);
    return matchesCategory && matchesSearch;
  }).toList();

  // Sort
  switch (sortMode) {
    case ExploreSortMode.rating:
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case ExploreSortMode.reviews:
      filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      break;
    case ExploreSortMode.nameAZ:
      filtered.sort((a, b) => a.name.compareTo(b.name));
      break;
  }

  return filtered;
});

// Trending tags
const trendingTags = [
  '🔥 Top Rated',
  '☕ Best Cafes',
  '🏥 Doctors',
  '💪 Gyms',
  '📚 Study Spots',
  '🍕 Food',
];

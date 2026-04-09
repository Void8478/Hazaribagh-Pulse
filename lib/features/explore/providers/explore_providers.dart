import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/explore_search_bundle.dart';
import '../services/supabase_global_search_service.dart';

enum ExploreContentType { all, places, posts, events }

enum ExploreSortMode {
  mostRelevant,
  newestFirst,
  oldestFirst,
  mostPopular,
  highestRated,
}

enum ExploreEventTiming { all, upcomingOnly, pastOnly }

class ExploreSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query.trim();
}

final exploreSearchQueryProvider =
    NotifierProvider<ExploreSearchQueryNotifier, String>(
  ExploreSearchQueryNotifier.new,
);

class ExploreContentTypeNotifier extends Notifier<ExploreContentType> {
  @override
  ExploreContentType build() => ExploreContentType.all;

  void set(ExploreContentType value) => state = value;
}

final exploreContentTypeProvider =
    NotifierProvider<ExploreContentTypeNotifier, ExploreContentType>(
  ExploreContentTypeNotifier.new,
);

class ExploreCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? category) => state = category;
}

final exploreCategoryProvider =
    NotifierProvider<ExploreCategoryNotifier, String?>(
  ExploreCategoryNotifier.new,
);

class ExploreLocationNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String location) => state = location.trim();
}

final exploreLocationProvider =
    NotifierProvider<ExploreLocationNotifier, String>(
  ExploreLocationNotifier.new,
);

class ExploreSortNotifier extends Notifier<ExploreSortMode> {
  @override
  ExploreSortMode build() => ExploreSortMode.mostRelevant;

  void set(ExploreSortMode mode) => state = mode;
}

final exploreSortProvider =
    NotifierProvider<ExploreSortNotifier, ExploreSortMode>(
  ExploreSortNotifier.new,
);

class ExploreVerifiedOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final exploreVerifiedOnlyProvider =
    NotifierProvider<ExploreVerifiedOnlyNotifier, bool>(
  ExploreVerifiedOnlyNotifier.new,
);

class ExploreSponsoredOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final exploreSponsoredOnlyProvider =
    NotifierProvider<ExploreSponsoredOnlyNotifier, bool>(
  ExploreSponsoredOnlyNotifier.new,
);

class ExploreEventTimingNotifier extends Notifier<ExploreEventTiming> {
  @override
  ExploreEventTiming build() => ExploreEventTiming.all;

  void set(ExploreEventTiming value) => state = value;
}

final exploreEventTimingProvider =
    NotifierProvider<ExploreEventTimingNotifier, ExploreEventTiming>(
  ExploreEventTimingNotifier.new,
);

final globalSearchServiceProvider = Provider<SupabaseGlobalSearchService>((ref) {
  return SupabaseGlobalSearchService();
});

final globalSearchResultsProvider =
    FutureProvider<ExploreSearchBundle>((ref) async {
  final query = ref.watch(exploreSearchQueryProvider);
  final category = ref.watch(exploreCategoryProvider);
  final sortMode = ref.watch(exploreSortProvider);
  final location = ref.watch(exploreLocationProvider);
  final contentType = ref.watch(exploreContentTypeProvider);
  final verifiedOnly = ref.watch(exploreVerifiedOnlyProvider);
  final sponsoredOnly = ref.watch(exploreSponsoredOnlyProvider);
  final eventTiming = ref.watch(exploreEventTimingProvider);

  return ref.watch(globalSearchServiceProvider).search(
        query: query,
        categoryName: category,
        sortMode: sortMode,
        location: location,
        contentType: contentType,
        verifiedOnly: verifiedOnly,
        sponsoredOnly: sponsoredOnly,
        eventTiming: eventTiming,
      );
});

const trendingTags = [
  'Top Rated',
  'Best Cafes',
  'Doctors',
  'Gyms',
  'Study Spots',
  'Food',
];

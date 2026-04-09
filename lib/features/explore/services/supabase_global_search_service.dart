import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../../models/post_model.dart';
import '../models/explore_search_bundle.dart';
import '../providers/explore_providers.dart';

class SupabaseGlobalSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, String>> _fetchCategoryIdsByName() async {
    final response = await _supabase.from('categories').select('id, name');
    final rows = (response as List).cast<Map<String, dynamic>>();
    return {
      for (final row in rows)
        if (row['name'] != null && row['id'] != null)
          row['name'].toString(): row['id'].toString(),
    };
  }

  Future<Map<String, String>> _fetchCategoryNamesById() async {
    final response = await _supabase.from('categories').select('id, name');
    final rows = (response as List).cast<Map<String, dynamic>>();
    return {
      for (final row in rows)
        if (row['id'] != null)
          row['id'].toString(): (row['name'] ?? 'Category').toString(),
    };
  }

  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    final response = await _supabase
        .from('profiles')
        .select('id, full_name, username, avatar_url')
        .filter('id', 'in', ids);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return {
      for (final row in rows)
        if (row['id'] != null)
          row['id'].toString(): Map<String, dynamic>.from(row),
    };
  }

  Future<Map<String, int>> _fetchLikeCounts(
    String contentType,
    Iterable<String> contentIds,
  ) async {
    final ids = contentIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    final response = await _supabase
        .from('user_likes')
        .select('content_id')
        .eq('content_type', contentType)
        .filter('content_id', 'in', ids);

    final counts = <String, int>{};
    for (final row in (response as List).cast<Map<String, dynamic>>()) {
      final contentId = row['content_id']?.toString();
      if (contentId == null || contentId.isEmpty) continue;
      final key = '$contentType:$contentId';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  String _sanitizeSearchTerm(String value) {
    return value
        .trim()
        .replaceAll(',', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ');
  }

  int _relevanceScore({
    required String query,
    required List<String> primaryFields,
    required List<String> secondaryFields,
    int popularity = 0,
    int rating = 0,
  }) {
    if (query.isEmpty) {
      return popularity + rating;
    }

    final normalized = query.toLowerCase();
    var score = 0;

    for (final field in primaryFields) {
      final value = field.toLowerCase();
      if (value == normalized) {
        score += 140;
      } else if (value.startsWith(normalized)) {
        score += 95;
      } else if (value.contains(normalized)) {
        score += 70;
      }
    }

    for (final field in secondaryFields) {
      final value = field.toLowerCase();
      if (value == normalized) {
        score += 55;
      } else if (value.startsWith(normalized)) {
        score += 40;
      } else if (value.contains(normalized)) {
        score += 25;
      }
    }

    return score + popularity + rating;
  }

  Future<ExploreSearchBundle> search({
    required String query,
    required String? categoryName,
    required ExploreSortMode sortMode,
    required String location,
    required ExploreContentType contentType,
    required bool verifiedOnly,
    required bool sponsoredOnly,
    required ExploreEventTiming eventTiming,
  }) async {
    final searchQuery = _sanitizeSearchTerm(query);
    final locationQuery = _sanitizeSearchTerm(location);
    final categoryIdsByName = await _fetchCategoryIdsByName();
    final categoryNamesById = await _fetchCategoryNamesById();
    final categoryId = categoryName == null ? null : categoryIdsByName[categoryName];

    final places = contentType == ExploreContentType.all ||
            contentType == ExploreContentType.places
        ? await _searchPlaces(
            searchQuery: searchQuery,
            locationQuery: locationQuery,
            categoryId: categoryId,
            categoryNamesById: categoryNamesById,
            verifiedOnly: verifiedOnly,
            sponsoredOnly: sponsoredOnly,
            limit: contentType == ExploreContentType.all ? 12 : 30,
          )
        : <PlaceModel>[];

    final posts = contentType == ExploreContentType.all ||
            contentType == ExploreContentType.posts
        ? await _searchPosts(
            searchQuery: searchQuery,
            locationQuery: locationQuery,
            categoryId: categoryId,
            limit: contentType == ExploreContentType.all ? 12 : 30,
          )
        : <PostModel>[];

    final events = contentType == ExploreContentType.all ||
            contentType == ExploreContentType.events
        ? await _searchEvents(
            searchQuery: searchQuery,
            locationQuery: locationQuery,
            categoryId: categoryId,
            categoryNamesById: categoryNamesById,
            eventTiming: eventTiming,
            limit: contentType == ExploreContentType.all ? 12 : 30,
          )
        : <EventModel>[];

    final likeCounts = <String, int>{}
      ..addAll(await _fetchLikeCounts('place', places.map((item) => item.id)))
      ..addAll(await _fetchLikeCounts('post', posts.map((item) => item.id)))
      ..addAll(await _fetchLikeCounts('event', events.map((item) => item.id)));

    _sortPlaces(places, sortMode, likeCounts, searchQuery);
    _sortPosts(posts, sortMode, likeCounts, searchQuery);
    _sortEvents(events, sortMode, likeCounts, searchQuery);

    return ExploreSearchBundle(
      places: places,
      posts: posts,
      events: events,
      likeCounts: likeCounts,
    );
  }

  Future<List<PlaceModel>> _searchPlaces({
    required String searchQuery,
    required String locationQuery,
    required String? categoryId,
    required Map<String, String> categoryNamesById,
    required bool verifiedOnly,
    required bool sponsoredOnly,
    required int limit,
  }) async {
    dynamic query = _supabase.from('listings').select();

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (verifiedOnly) {
      query = query.eq('is_verified', true);
    }
    if (sponsoredOnly) {
      query = query.eq('is_sponsored', true);
    }
    if (locationQuery.isNotEmpty) {
      query = query.or(
        'location.ilike.%$locationQuery%,address.ilike.%$locationQuery%',
      );
    }
    if (searchQuery.isNotEmpty) {
      query = query.or(
        'name.ilike.%$searchQuery%,title.ilike.%$searchQuery%,description.ilike.%$searchQuery%,address.ilike.%$searchQuery%,location.ilike.%$searchQuery%',
      );
    }

    query = query.order('created_at', ascending: false).limit(limit);
    final response = await query;
    final rows = (response as List).cast<Map<String, dynamic>>();
    final profilesById = await _fetchProfilesByIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final resolvedCategoryId = row['category_id']?.toString();
      final userId = row['user_id']?.toString();
      if ((merged['category'] == null ||
              merged['category'].toString().trim().isEmpty) &&
          resolvedCategoryId != null &&
          categoryNamesById.containsKey(resolvedCategoryId)) {
        merged['category'] = categoryNamesById[resolvedCategoryId];
      }
      if (userId != null) {
        merged['profiles'] = profilesById[userId];
      }
      return PlaceModel.fromJson(merged);
    }).toList();
  }

  Future<List<PostModel>> _searchPosts({
    required String searchQuery,
    required String locationQuery,
    required String? categoryId,
    required int limit,
  }) async {
    dynamic query = _supabase
        .from('posts')
        .select('*, categories(id, name)')
        .eq('status', 'published');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (locationQuery.isNotEmpty) {
      query = query.ilike('location', '%$locationQuery%');
    }
    if (searchQuery.isNotEmpty) {
      query = query.or(
        'title.ilike.%$searchQuery%,description.ilike.%$searchQuery%,location.ilike.%$searchQuery%',
      );
    }

    query = query.order('created_at', ascending: false).limit(limit);
    final response = await query;
    final rows = (response as List).cast<Map<String, dynamic>>();
    final profilesById = await _fetchProfilesByIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final userId = row['user_id']?.toString();
      if (userId != null) {
        merged['profiles'] = profilesById[userId];
      }
      return PostModel.fromJson(merged);
    }).toList();
  }

  Future<List<EventModel>> _searchEvents({
    required String searchQuery,
    required String locationQuery,
    required String? categoryId,
    required Map<String, String> categoryNamesById,
    required ExploreEventTiming eventTiming,
    required int limit,
  }) async {
    dynamic query = _supabase.from('events').select('*, categories(id, name)');
    final now = DateTime.now().toUtc().toIso8601String();

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (locationQuery.isNotEmpty) {
      query = query.or(
        'location.ilike.%$locationQuery%,address.ilike.%$locationQuery%',
      );
    }
    if (eventTiming == ExploreEventTiming.upcomingOnly) {
      query = query.gte('date', now);
    } else if (eventTiming == ExploreEventTiming.pastOnly) {
      query = query.lt('date', now);
    }
    if (searchQuery.isNotEmpty) {
      query = query.or(
        'title.ilike.%$searchQuery%,description.ilike.%$searchQuery%,location.ilike.%$searchQuery%,organizer.ilike.%$searchQuery%,address.ilike.%$searchQuery%',
      );
    }

    query = query
        .order(
          'date',
          ascending: eventTiming == ExploreEventTiming.pastOnly,
        )
        .limit(limit);
    final response = await query;
    final rows = (response as List).cast<Map<String, dynamic>>();
    final profilesById = await _fetchProfilesByIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final categoryMap = row['categories'] is Map<String, dynamic>
          ? row['categories'] as Map<String, dynamic>
          : row['categories'] is Map
              ? Map<String, dynamic>.from(row['categories'] as Map)
              : null;
      final resolvedCategoryId =
          row['category_id']?.toString() ?? categoryMap?['id']?.toString();
      if ((merged['category'] == null ||
              merged['category'].toString().trim().isEmpty) &&
          resolvedCategoryId != null &&
          categoryNamesById.containsKey(resolvedCategoryId)) {
        merged['category'] = categoryNamesById[resolvedCategoryId];
      }
      final userId = row['user_id']?.toString();
      if (userId != null) {
        merged['profiles'] = profilesById[userId];
      }
      return EventModel.fromJson(merged);
    }).toList();
  }

  void _sortPlaces(
    List<PlaceModel> places,
    ExploreSortMode sortMode,
    Map<String, int> likeCounts,
    String query,
  ) {
    switch (sortMode) {
      case ExploreSortMode.mostRelevant:
        places.sort((a, b) {
          final aScore = _relevanceScore(
            query: query,
            primaryFields: [a.name, a.category],
            secondaryFields: [a.description, a.location, a.address],
            popularity: (likeCounts['place:${a.id}'] ?? 0) * 4,
            rating: (a.rating * 10).round(),
          );
          final bScore = _relevanceScore(
            query: query,
            primaryFields: [b.name, b.category],
            secondaryFields: [b.description, b.location, b.address],
            popularity: (likeCounts['place:${b.id}'] ?? 0) * 4,
            rating: (b.rating * 10).round(),
          );
          if (bScore != aScore) return bScore.compareTo(aScore);
          return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        });
        break;
      case ExploreSortMode.newestFirst:
        places.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
        break;
      case ExploreSortMode.oldestFirst:
        places.sort((a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
        break;
      case ExploreSortMode.mostPopular:
        places.sort((a, b) {
          final aPopularity = (likeCounts['place:${a.id}'] ?? 0) + a.reviewCount;
          final bPopularity = (likeCounts['place:${b.id}'] ?? 0) + b.reviewCount;
          if (bPopularity != aPopularity) {
            return bPopularity.compareTo(aPopularity);
          }
          return b.rating.compareTo(a.rating);
        });
        break;
      case ExploreSortMode.highestRated:
        places.sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;
          return b.reviewCount.compareTo(a.reviewCount);
        });
        break;
    }
  }

  void _sortPosts(
    List<PostModel> posts,
    ExploreSortMode sortMode,
    Map<String, int> likeCounts,
    String query,
  ) {
    switch (sortMode) {
      case ExploreSortMode.mostRelevant:
        posts.sort((a, b) {
          final aScore = _relevanceScore(
            query: query,
            primaryFields: [a.title, a.categoryName],
            secondaryFields: [a.description, a.location],
            popularity: (likeCounts['post:${a.id}'] ?? 0) * 5,
          );
          final bScore = _relevanceScore(
            query: query,
            primaryFields: [b.title, b.categoryName],
            secondaryFields: [b.description, b.location],
            popularity: (likeCounts['post:${b.id}'] ?? 0) * 5,
          );
          if (bScore != aScore) return bScore.compareTo(aScore);
          return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        });
        break;
      case ExploreSortMode.newestFirst:
        posts.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
        break;
      case ExploreSortMode.oldestFirst:
        posts.sort((a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
        break;
      case ExploreSortMode.mostPopular:
      case ExploreSortMode.highestRated:
        posts.sort((a, b) {
          final likeCompare = (likeCounts['post:${b.id}'] ?? 0)
              .compareTo(likeCounts['post:${a.id}'] ?? 0);
          if (likeCompare != 0) return likeCompare;
          return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        });
        break;
    }
  }

  void _sortEvents(
    List<EventModel> events,
    ExploreSortMode sortMode,
    Map<String, int> likeCounts,
    String query,
  ) {
    switch (sortMode) {
      case ExploreSortMode.mostRelevant:
        events.sort((a, b) {
          final aScore = _relevanceScore(
            query: query,
            primaryFields: [a.title, a.category],
            secondaryFields: [a.description, a.location, a.organizer, a.address],
            popularity: (likeCounts['event:${a.id}'] ?? 0) * 5,
          );
          final bScore = _relevanceScore(
            query: query,
            primaryFields: [b.title, b.category],
            secondaryFields: [b.description, b.location, b.organizer, b.address],
            popularity: (likeCounts['event:${b.id}'] ?? 0) * 5,
          );
          if (bScore != aScore) return bScore.compareTo(aScore);
          return b.date.compareTo(a.date);
        });
        break;
      case ExploreSortMode.newestFirst:
        events.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ExploreSortMode.oldestFirst:
        events.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ExploreSortMode.mostPopular:
      case ExploreSortMode.highestRated:
        events.sort((a, b) {
          final likeCompare = (likeCounts['event:${b.id}'] ?? 0)
              .compareTo(likeCounts['event:${a.id}'] ?? 0);
          if (likeCompare != 0) return likeCompare;
          return a.date.compareTo(b.date);
        });
        break;
    }
  }
}

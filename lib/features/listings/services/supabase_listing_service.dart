import 'package:hazaribagh_pulse/models/category_model.dart';
import 'package:hazaribagh_pulse/models/place_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseListingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByUserIds(
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
        if (row['id'] != null) row['id'].toString(): Map<String, dynamic>.from(row),
    };
  }

  Map<String, dynamic> _mergeListingWithCategory(
    Map<String, dynamic> listing,
    Map<String, String> categoryNamesById, {
    Map<String, Map<String, dynamic>> profilesById = const {},
  }) {
    final merged = Map<String, dynamic>.from(listing);
    final categoryId = listing['category_id']?.toString();
    final userId = listing['user_id']?.toString();

    if ((merged['category'] == null || merged['category'].toString().trim().isEmpty) &&
        categoryId != null &&
        categoryNamesById.containsKey(categoryId)) {
      merged['category'] = categoryNamesById[categoryId];
    }

    if (userId != null && profilesById.containsKey(userId)) {
      merged['profiles'] = profilesById[userId];
    }

    return merged;
  }

  Future<Map<String, String>> _fetchActiveCategoryNamesById() async {
    final response = await _supabase
        .from('categories')
        .select('id, name')
        .eq('is_active', true)
        .order('manual_rank', ascending: true)
        .order('name', ascending: true);
    final rows = (response as List).cast<Map<String, dynamic>>();

    return {
      for (final row in rows)
        if (row['id'] != null) row['id'].toString(): (row['name'] ?? 'Category').toString(),
    };
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('manual_rank', ascending: true)
        .order('name', ascending: true);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(CategoryModel.fromJson).toList();
  }

  Future<List<PlaceModel>> _fetchListings({
    int? maxResults,
    bool featuredOnly = false,
    bool excludeFeatured = false,
    String? categoryId,
    bool? verifiedOnly,
  }) async {
    final categoryNamesById = await _fetchActiveCategoryNamesById();
    dynamic query = _supabase.from('listings').select().eq('status', 'active');

    if (featuredOnly) {
      query = query.eq('is_featured', true);
    }
    if (excludeFeatured) {
      query = query.eq('is_featured', false);
    }
    if (verifiedOnly != null) {
      query = query.eq('is_verified', verifiedOnly);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', _normalizedId(categoryId));
    }

    query = query
        .order('is_featured', ascending: false)
        .order('manual_rank', ascending: true)
        .order('created_at', ascending: false);

    if (maxResults != null) {
      query = query.limit(maxResults);
    }

    final response = await query;
    final rows = (response as List).cast<Map<String, dynamic>>();
    final profilesById = await _fetchProfilesByUserIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    final listings = rows
        .map(
          (data) => _mergeListingWithCategory(
            data,
            categoryNamesById,
            profilesById: profilesById,
          ),
        )
        .map(PlaceModel.fromJson)
        .toList();

    listings.sort((a, b) {
      final featuredCompare = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
      if (featuredCompare != 0) return featuredCompare;
      final rankCompare = a.manualRank.compareTo(b.manualRank);
      if (rankCompare != 0) return rankCompare;
      return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    });

    return listings;
  }

  Future<List<PlaceModel>> getAllListings({int? limit}) async {
    return _fetchListings(maxResults: limit);
  }

  Future<List<PlaceModel>> getFeaturedListings({int limit = 8}) async {
    return _fetchListings(maxResults: limit, featuredOnly: true);
  }

  Future<List<PlaceModel>> getRankedListings({int limit = 8}) async {
    return _fetchListings(maxResults: limit);
  }

  Future<List<PlaceModel>> getCategoryListings(
    String categoryId, {
    int? limit,
  }) async {
    return _fetchListings(categoryId: categoryId, maxResults: limit);
  }

  Future<PlaceModel> getListingById(String id) async {
    final categoryNamesById = await _fetchActiveCategoryNamesById();
    final data = await _supabase
        .from('listings')
        .select()
        .eq('id', _normalizedId(id))
        .eq('status', 'active')
        .maybeSingle();
    if (data == null) {
      throw Exception('Listing not found');
    }

    final profilesById = await _fetchProfilesByUserIds([
      data['user_id']?.toString() ?? '',
    ]);

    return PlaceModel.fromJson(
      _mergeListingWithCategory(
        Map<String, dynamic>.from(data),
        categoryNamesById,
        profilesById: profilesById,
      ),
    );
  }

  Future<List<PlaceModel>> getListingsByUserId(String userId) async {
    final categoryNamesById = await _fetchActiveCategoryNamesById();
    final response = await _supabase
        .from('listings')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('is_featured', ascending: false)
        .order('manual_rank', ascending: true)
        .order('created_at', ascending: false);

    final rows = (response as List).cast<Map<String, dynamic>>();
    final profilesById = await _fetchProfilesByUserIds([userId]);
    return rows
        .map(
          (data) => _mergeListingWithCategory(
            data,
            categoryNamesById,
            profilesById: profilesById,
          ),
        )
        .map(PlaceModel.fromJson)
        .toList();
  }
}

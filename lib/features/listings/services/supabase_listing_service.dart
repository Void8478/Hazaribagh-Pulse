import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hazaribagh_pulse/models/category_model.dart';
import 'package:hazaribagh_pulse/models/place_model.dart';

class SupabaseListingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  Map<String, dynamic> _mergeListingWithCategory(
    Map<String, dynamic> listing,
    Map<String, String> categoryNamesById,
  ) {
    final merged = Map<String, dynamic>.from(listing);
    final categoryId = listing['category_id']?.toString();

    if ((merged['category'] == null || merged['category'].toString().trim().isEmpty) &&
        categoryId != null &&
        categoryNamesById.containsKey(categoryId)) {
      merged['category'] = categoryNamesById[categoryId];
    }

    return merged;
  }

  Future<Map<String, String>> _fetchCategoryNamesById() async {
    final response = await _supabase.from('categories').select();
    final rows = (response as List).cast<Map<String, dynamic>>();

    return {
      for (final row in rows)
        if (row['id'] != null)
          row['id'].toString():
              (row['name'] ?? row['title'] ?? row['label'] ?? 'Category').toString(),
    };
  }

  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('display_order', ascending: true)
          .order('name', ascending: true);
      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map(CategoryModel.fromJson).toList();
    } catch (_) {
      final response = await _supabase.from('categories').select();
      final rows = (response as List).cast<Map<String, dynamic>>();
      final categories = rows.map(CategoryModel.fromJson).toList();
      categories.sort((a, b) {
        final orderCompare = a.displayOrder.compareTo(b.displayOrder);
        if (orderCompare != 0) return orderCompare;
        return a.name.compareTo(b.name);
      });
      return categories;
    }
  }

  Future<List<PlaceModel>> _fetchListings({
    String? orderBy,
    bool ascending = false,
    String? secondaryOrderBy,
    bool secondaryAscending = false,
    bool? sponsoredOnly,
    bool? verifiedOnly,
    int? maxResults,
  }) async {
    try {
      final categoryNamesById = await _fetchCategoryNamesById();
      dynamic query = _supabase.from('listings').select();

      if (sponsoredOnly != null) {
        query = query.eq('is_sponsored', sponsoredOnly);
      }
      if (verifiedOnly != null) {
        query = query.eq('is_verified', verifiedOnly);
      }
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      if (secondaryOrderBy != null) {
        query = query.order(secondaryOrderBy, ascending: secondaryAscending);
      }
      if (maxResults != null) {
        query = query.limit(maxResults);
      }

      final response = await query;
      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows
          .map((data) => _mergeListingWithCategory(data, categoryNamesById))
          .map(PlaceModel.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  Future<List<PlaceModel>> getAllListings() async {
    return _fetchListings();
  }

  Future<List<PlaceModel>> getTrendingListings({int limit = 8}) async {
    try {
      final listings = await _fetchListings(
        orderBy: 'is_sponsored',
        ascending: false,
        secondaryOrderBy: 'rating',
        secondaryAscending: false,
        maxResults: limit,
      );
      listings.sort((a, b) {
        final sponsoredCompare =
            (b.isSponsored ? 1 : 0).compareTo(a.isSponsored ? 1 : 0);
        if (sponsoredCompare != 0) return sponsoredCompare;
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.reviewCount.compareTo(a.reviewCount);
      });
      return listings.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch trending listings: $e');
    }
  }

  Future<List<PlaceModel>> getTopRatedListings({int limit = 8}) async {
    try {
      final listings = await _fetchListings(
        orderBy: 'rating',
        ascending: false,
        secondaryOrderBy: 'review_count',
        secondaryAscending: false,
        verifiedOnly: true,
        maxResults: limit,
      );
      listings.sort((a, b) {
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.reviewCount.compareTo(a.reviewCount);
      });
      return listings.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch top rated listings: $e');
    }
  }

  Future<List<PlaceModel>> getHiddenGemListings({int limit = 8}) async {
    try {
      final listings = await _fetchListings(
        orderBy: 'review_count',
        ascending: true,
        secondaryOrderBy: 'created_at',
        secondaryAscending: false,
        maxResults: limit * 2,
      );
      final filtered = listings.where((place) => !place.isSponsored).toList();
      return filtered.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch hidden gems: $e');
    }
  }

  Future<PlaceModel> getListingById(String id) async {
    try {
      final categoryNamesById = await _fetchCategoryNamesById();
      final data = await _supabase
          .from('listings')
          .select()
          .eq('id', _normalizedId(id))
          .maybeSingle();
      if (data == null) {
        throw Exception('Listing not found');
      }
      return PlaceModel.fromJson(
        _mergeListingWithCategory(
          Map<String, dynamic>.from(data),
          categoryNamesById,
        ),
      );
    } catch (e) {
      throw Exception('Failed to fetch listing details: $e');
    }
  }
}

import '../../../../models/category_model.dart';
import '../../../../models/place_model.dart';
import '../services/supabase_listing_service.dart';

class ListingRepository {
  final SupabaseListingService _service;

  ListingRepository(this._service);

  Future<List<PlaceModel>> fetchAllListings() {
    return _service.getAllListings();
  }

  Future<List<PlaceModel>> fetchFeaturedListings({int limit = 8}) {
    return _service.getFeaturedListings(limit: limit);
  }

  Future<List<PlaceModel>> fetchRankedListings({int limit = 8}) {
    return _service.getRankedListings(limit: limit);
  }

  Future<List<PlaceModel>> fetchCategoryListings(
    String categoryId, {
    int? limit,
  }) {
    return _service.getCategoryListings(categoryId, limit: limit);
  }

  Future<List<CategoryModel>> fetchAllCategories() {
    return _service.getAllCategories();
  }

  Future<PlaceModel> fetchListingById(String id) {
    return _service.getListingById(id);
  }

  Future<List<PlaceModel>> fetchListingsByUserId(String userId) {
    return _service.getListingsByUserId(userId);
  }
}

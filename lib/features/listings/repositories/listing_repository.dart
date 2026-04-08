import '../../../../models/category_model.dart';
import '../../../../models/place_model.dart';
import '../services/supabase_listing_service.dart';

class ListingRepository {
  final SupabaseListingService _service;

  ListingRepository(this._service);

  Future<List<PlaceModel>> fetchAllListings() {
    return _service.getAllListings();
  }

  Future<List<PlaceModel>> fetchTrendingListings({int limit = 8}) {
    return _service.getTrendingListings(limit: limit);
  }

  Future<List<PlaceModel>> fetchTopRatedListings({int limit = 8}) {
    return _service.getTopRatedListings(limit: limit);
  }

  Future<List<PlaceModel>> fetchHiddenGemListings({int limit = 8}) {
    return _service.getHiddenGemListings(limit: limit);
  }

  Future<List<CategoryModel>> fetchAllCategories() {
    return _service.getAllCategories();
  }

  Future<PlaceModel> fetchListingById(String id) {
    return _service.getListingById(id);
  }
}

import '../../../../models/place_model.dart';
import '../services/supabase_listing_service.dart';

class ListingRepository {
  final SupabaseListingService _service;

  ListingRepository(this._service);

  Future<List<PlaceModel>> fetchAllListings() {
    return _service.getAllListings();
  }

  Future<PlaceModel> fetchListingById(String id) {
    return _service.getListingById(id);
  }
}

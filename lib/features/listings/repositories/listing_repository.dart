import '../../../../models/place_model.dart';
import '../services/firestore_listing_service.dart';

class ListingRepository {
  final FirestoreListingService _service;

  ListingRepository(this._service);

  Future<List<PlaceModel>> fetchAllListings() {
    return _service.getAllListings();
  }

  Future<PlaceModel> fetchListingById(String id) {
    return _service.getListingById(id);
  }
}

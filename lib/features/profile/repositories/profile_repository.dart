import '../services/firestore_profile_service.dart';
import '../../../../models/review_model.dart';

class ProfileRepository {
  final FirestoreProfileService _service;

  ProfileRepository(this._service);

  Future<List<ReviewModel>> getUserReviews(String userId) {
    return _service.getUserReviews(userId);
  }
}

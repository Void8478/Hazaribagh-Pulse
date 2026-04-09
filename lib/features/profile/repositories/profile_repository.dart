import 'package:hazaribagh_pulse/models/review_model.dart';
import 'package:hazaribagh_pulse/models/user_model.dart';

import '../services/supabase_profile_service.dart';

class ProfileRepository {
  final SupabaseProfileService _service;

  ProfileRepository(this._service);

  Future<List<ReviewModel>> getUserReviews(String userId) {
    return _service.getUserReviews(userId);
  }

  Future<UserModel> getUserProfile(String userId) {
    return _service.getUserProfile(userId);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) {
    return _service.updateProfile(userId, data);
  }

  Future<void> deleteUserData(String userId) {
    return _service.deleteUserData(userId);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/review_model.dart';
import '../../../../models/user_model.dart';

class SupabaseProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel> getUserProfile(String userId) async {
    try {
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('reviews')
          .select()
          .eq('author_id', userId)
          .order('timestamp', ascending: false);
      return response.map((data) => ReviewModel.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  /// Update user profile fields in Supabase
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      // Typically set updated_at automatically via DB trigger, or explicitly here:
      data['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Delete user data: Auth user deletion will CASCADE deleting profile doc,
  /// but reviews were defined with ON DELETE SET NULL, keeping the text intact.
  Future<void> deleteUserData(String userId) async {
    try {
      // 1. Update reviews to clear PII name/image
      await _supabase.from('reviews')
          .update({
            'author_name': 'Deleted User',
            'author_image_url': ''
          })
          .eq('author_id', userId);

      // 2. The edge function/auth API handles deleting the auth user, which cascades to delete the profile.
      // Or if the app wants to delete the auth user right here:
      // Note: deleting a user requires admin rights or the user itself using adminApi. 
      // Instead, we just delete the profile (which is not right, users can't delete their own row usually unless RLS allows.)
      // We will assume a delete RPC or standard API is used by the client.
      await _supabase.rpc('delete_user_account');
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}

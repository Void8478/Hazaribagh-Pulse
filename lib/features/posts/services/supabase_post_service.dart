import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hazaribagh_pulse/models/post_model.dart';

class SupabasePostService {
  SupabasePostService(this._supabase);

  final SupabaseClient _supabase;

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  Future<List<PostModel>> getRecentPosts({int limit = 6}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('*, categories(id, name)')
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => PostModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  Future<PostModel> getPostById(String id) async {
    try {
      final data = await _supabase
          .from('posts')
          .select('*, categories(id, name)')
          .eq('id', _normalizedId(id))
          .single();

      return PostModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch post details: $e');
    }
  }
}

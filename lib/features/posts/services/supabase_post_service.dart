import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hazaribagh_pulse/models/post_model.dart';

class SupabasePostService {
  SupabasePostService(this._supabase);

  final SupabaseClient _supabase;

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

  Future<List<PostModel>> _mapPostsWithProfiles(List<Map<String, dynamic>> rows) async {
    final profilesById = await _fetchProfilesByUserIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final userId = row['user_id']?.toString() ?? '';
      merged['profiles'] = profilesById[userId];
      return PostModel.fromJson(merged);
    }).toList();
  }

  Future<List<PostModel>> getRecentPosts({int limit = 6}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('*, categories(id, name)')
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = (response as List).cast<Map<String, dynamic>>();
      return _mapPostsWithProfiles(rows);
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  Future<List<PostModel>> getPostsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('*, categories(id, name)')
          .eq('user_id', userId)
          .eq('status', 'published')
          .order('created_at', ascending: false);

      final rows = (response as List).cast<Map<String, dynamic>>();
      return _mapPostsWithProfiles(rows);
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  Future<PostModel> getPostById(String id) async {
    try {
      final data = Map<String, dynamic>.from(await _supabase
          .from('posts')
          .select('*, categories(id, name)')
          .eq('id', _normalizedId(id))
          .single());

      final profilesById = await _fetchProfilesByUserIds([
        data['user_id']?.toString() ?? '',
      ]);
      data['profiles'] = profilesById[data['user_id']?.toString() ?? ''];

      return PostModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch post details: $e');
    }
  }
}

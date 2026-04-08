import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInteractionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- LIKES ---

  Future<Set<String>> getUserLikes(String contentType) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    try {
      final response = await _supabase
          .from('user_likes')
          .select('content_id')
          .eq('user_id', user.id)
          .eq('content_type', contentType);

      return (response as List).map((row) => row['content_id'] as String).toSet();
    } catch (e) {
      throw Exception('Failed to fetch user likes: $e');
    }
  }

  Future<void> toggleLike(String contentId, String contentType, bool isLiking) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to like');

    try {
      if (isLiking) {
        await _supabase.from('user_likes').insert({
          'user_id': user.id,
          'content_id': contentId,
          'content_type': contentType,
        });
      } else {
        await _supabase
            .from('user_likes')
            .delete()
            .match({'user_id': user.id, 'content_id': contentId, 'content_type': contentType});
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  Future<int> getLikeCount(String contentId, String contentType) async {
    try {
      final response = await _supabase
          .from('user_likes')
          .select('content_id')
          .eq('content_id', contentId)
          .eq('content_type', contentType)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  // --- BOOKMARKS ---

  Future<Set<String>> getUserBookmarks(String contentType) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    try {
      final response = await _supabase
          .from('user_bookmarks')
          .select('content_id')
          .eq('user_id', user.id)
          .eq('content_type', contentType);

      return (response as List).map((row) => row['content_id'] as String).toSet();
    } catch (e) {
      throw Exception('Failed to fetch user bookmarks: $e');
    }
  }

  Future<void> toggleBookmark(String contentId, String contentType, bool isSaving) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to save');

    try {
      if (isSaving) {
        await _supabase.from('user_bookmarks').insert({
          'user_id': user.id,
          'content_id': contentId,
          'content_type': contentType,
        });
      } else {
        await _supabase
            .from('user_bookmarks')
            .delete()
            .match({'user_id': user.id, 'content_id': contentId, 'content_type': contentType});
      }
    } catch (e) {
      throw Exception('Failed to toggle bookmark: $e');
    }
  }
}

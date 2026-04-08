import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hazaribagh_pulse/models/comment_model.dart';

enum CommentTargetType { post, event }

class CommentTarget {
  const CommentTarget({
    required this.type,
    required this.contentId,
  });

  final CommentTargetType type;
  final String contentId;

  String get tableName =>
      type == CommentTargetType.post ? 'post_comments' : 'event_comments';

  String get foreignKeyColumn =>
      type == CommentTargetType.post ? 'post_id' : 'event_id';

  @override
  bool operator ==(Object other) {
    return other is CommentTarget &&
        other.type == type &&
        other.contentId == contentId;
  }

  @override
  int get hashCode => Object.hash(type, contentId);
}

class SupabaseCommentService {
  SupabaseCommentService(this._supabase);

  final SupabaseClient _supabase;

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  Future<List<CommentModel>> getComments(CommentTarget target) async {
    try {
      final response = await _supabase
          .from(target.tableName)
          .select('*, profiles(id, full_name, username, avatar_url)')
          .eq(target.foreignKeyColumn, _normalizedId(target.contentId))
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (data) => CommentModel.fromJson(
              Map<String, dynamic>.from(data as Map),
              contentIdKey: target.foreignKeyColumn,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  Future<void> addComment(CommentTarget target, String text) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('auth_required');
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw Exception('Comment cannot be empty.');
    }

    try {
      await _supabase.from(target.tableName).insert({
        target.foreignKeyColumn: _normalizedId(target.contentId),
        'user_id': user.id,
        'text': trimmedText,
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}

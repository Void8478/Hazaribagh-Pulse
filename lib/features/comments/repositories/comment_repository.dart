import 'package:hazaribagh_pulse/models/comment_model.dart';
import '../services/supabase_comment_service.dart';

class CommentRepository {
  CommentRepository(this._service);

  final SupabaseCommentService _service;

  Future<List<CommentModel>> fetchComments(CommentTarget target) {
    return _service.getComments(target);
  }

  Future<void> createComment(CommentTarget target, String text) {
    return _service.addComment(target, text);
  }
}

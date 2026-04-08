import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../../../models/comment_model.dart';
import '../repositories/comment_repository.dart';
import '../services/supabase_comment_service.dart';

final commentServiceProvider = Provider<SupabaseCommentService>((ref) {
  return SupabaseCommentService(ref.watch(supabaseClientProvider));
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(commentServiceProvider));
});

final commentsProvider =
    FutureProvider.family<List<CommentModel>, CommentTarget>((ref, target) {
  return ref.watch(commentRepositoryProvider).fetchComments(target);
});

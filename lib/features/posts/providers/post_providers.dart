import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../../../models/post_model.dart';
import '../services/supabase_post_service.dart';

final postServiceProvider = Provider<SupabasePostService>((ref) {
  return SupabasePostService(ref.watch(supabaseClientProvider));
});

final recentPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.watch(postServiceProvider).getRecentPosts();
});

final postDetailProvider = FutureProvider.family<PostModel, String>((ref, id) async {
  return ref.watch(postServiceProvider).getPostById(id);
});

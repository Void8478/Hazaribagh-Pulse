import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_interaction_service.dart';

final interactionServiceProvider = Provider<SupabaseInteractionService>((ref) {
  return SupabaseInteractionService();
});

// A provider to fetch live count. Key format: "contentType:contentId"
final itemLikeCountProvider = FutureProvider.family.autoDispose<int, String>((ref, key) async {
  final parts = key.split(':');
  if (parts.length != 2) return 0;
  final contentType = parts[0];
  final contentId = parts[1];
  return ref.watch(interactionServiceProvider).getLikeCount(contentId, contentType);
});

class UserLikesNotifier extends AsyncNotifier<Set<String>> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Set<String>> build() async {
    final service = ref.watch(interactionServiceProvider);
    try {
      final postLikes = await service.getUserLikes('post');
      final placeLikes = await service.getUserLikes('place');
      final eventLikes = await service.getUserLikes('event');
      return {...postLikes, ...placeLikes, ...eventLikes};
    } catch (_) {
      return {};
    }
  }

  Future<void> toggleLike(String contentId, String contentType) async {
    if (_supabase.auth.currentUser == null) {
      throw Exception('auth_required');
    }

    final currentLikes = state.value ?? {};
    final isLiking = !currentLikes.contains(contentId);

    // Optimistic UI Update
    if (isLiking) {
      state = AsyncValue.data({...currentLikes, contentId});
    } else {
      state = AsyncValue.data(
          Set.from(currentLikes)..remove(contentId));
    }

    // Background Database update
    try {
      await ref.read(interactionServiceProvider).toggleLike(contentId, contentType, isLiking);
      // Invalidate count provider so it instantly refetches Live count
      ref.invalidate(itemLikeCountProvider('$contentType:$contentId'));
    } catch (err, stack) {
      // Revert on failure
      state = AsyncValue.data(currentLikes);
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }
}

final userLikesProvider = AsyncNotifierProvider<UserLikesNotifier, Set<String>>(() {
  return UserLikesNotifier();
});

class UserBookmarksNotifier extends AsyncNotifier<Set<String>> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Set<String>> build() async {
    final service = ref.watch(interactionServiceProvider);
    try {
      final postSaves = await service.getUserBookmarks('post');
      final placeSaves = await service.getUserBookmarks('place');
      final eventSaves = await service.getUserBookmarks('event');
      return {...postSaves, ...placeSaves, ...eventSaves};
    } catch (_) {
      return {};
    }
  }

  Future<void> toggleBookmark(String contentId, String contentType) async {
    if (_supabase.auth.currentUser == null) {
      throw Exception('auth_required');
    }

    final currentSaves = state.value ?? {};
    final isSaving = !currentSaves.contains(contentId);

    // Optimistic UI Update
    if (isSaving) {
      state = AsyncValue.data({...currentSaves, contentId});
    } else {
      state = AsyncValue.data(
          Set.from(currentSaves)..remove(contentId));
    }

    // Background Database update
    try {
      await ref.read(interactionServiceProvider).toggleBookmark(contentId, contentType, isSaving);
    } catch (err, stack) {
      // Revert on failure
      state = AsyncValue.data(currentSaves);
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }
}

final userBookmarksProvider = AsyncNotifierProvider<UserBookmarksNotifier, Set<String>>(() {
  return UserBookmarksNotifier();
});

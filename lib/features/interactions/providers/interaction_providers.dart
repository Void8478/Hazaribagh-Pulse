import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/services/auth_provider.dart';
import '../services/supabase_interaction_service.dart';

String interactionKey(String contentType, String contentId) =>
    '$contentType:$contentId';

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
    ref.watch(authProvider.select((value) => value.user?.id));
    final service = ref.watch(interactionServiceProvider);
    try {
      final postLikes = await service.getUserLikes('post');
      final placeLikes = await service.getUserLikes('place');
      final eventLikes = await service.getUserLikes('event');
      return {
        ...postLikes.map((id) => interactionKey('post', id)),
        ...placeLikes.map((id) => interactionKey('place', id)),
        ...eventLikes.map((id) => interactionKey('event', id)),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> toggleLike(String contentId, String contentType) async {
    if (_supabase.auth.currentUser == null) {
      throw Exception('auth_required');
    }

    final key = interactionKey(contentType, contentId);
    final currentLikes = state.value ?? {};
    final isLiking = !currentLikes.contains(key);

    if (isLiking) {
      state = AsyncValue.data({...currentLikes, key});
    } else {
      state = AsyncValue.data(Set<String>.from(currentLikes)..remove(key));
    }

    try {
      await ref
          .read(interactionServiceProvider)
          .toggleLike(contentId, contentType, isLiking);
      ref.invalidate(itemLikeCountProvider('$contentType:$contentId'));
    } catch (err, stack) {
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
    ref.watch(authProvider.select((value) => value.user?.id));
    final service = ref.watch(interactionServiceProvider);
    try {
      final postSaves = await service.getUserBookmarks('post');
      final placeSaves = await service.getUserBookmarks('place');
      final eventSaves = await service.getUserBookmarks('event');
      return {
        ...postSaves.map((id) => interactionKey('post', id)),
        ...placeSaves.map((id) => interactionKey('place', id)),
        ...eventSaves.map((id) => interactionKey('event', id)),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> toggleBookmark(String contentId, String contentType) async {
    if (_supabase.auth.currentUser == null) {
      throw Exception('auth_required');
    }

    final key = interactionKey(contentType, contentId);
    final currentSaves = state.value ?? {};
    final isSaving = !currentSaves.contains(key);

    if (isSaving) {
      state = AsyncValue.data({...currentSaves, key});
    } else {
      state = AsyncValue.data(Set<String>.from(currentSaves)..remove(key));
    }

    try {
      await ref
          .read(interactionServiceProvider)
          .toggleBookmark(contentId, contentType, isSaving);
    } catch (err, stack) {
      state = AsyncValue.data(currentSaves);
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }
}

final userBookmarksProvider = AsyncNotifierProvider<UserBookmarksNotifier, Set<String>>(() {
  return UserBookmarksNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/event_model.dart';
import '../../../../models/place_model.dart';
import '../../../core/network/supabase_client.dart';
import '../../interactions/providers/interaction_providers.dart';
import '../repositories/bookmark_repository.dart';
import '../services/supabase_bookmark_service.dart';

final bookmarkServiceProvider = Provider<SupabaseBookmarkService>((ref) {
  return SupabaseBookmarkService();
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final service = ref.watch(bookmarkServiceProvider);
  return BookmarkRepository(service);
});

final savedPlacesProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final savedKeys = await ref.watch(userBookmarksProvider.future);
  final savedIds = savedKeys
      .where((key) => key.startsWith('place:'))
      .map((key) => key.substring('place:'.length))
      .toList();

  if (savedIds.isEmpty) {
    return [];
  }

  final chunk = savedIds.take(20).toList();
  final response = await supabase
      .from('listings')
      .select()
      .filter('id', 'in', chunk);

  final places = (response as List)
      .map((data) => PlaceModel.fromJson(data as Map<String, dynamic>))
      .toList();
  places.sort((a, b) => chunk.indexOf(a.id).compareTo(chunk.indexOf(b.id)));
  return places;
});

final savedEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final savedKeys = await ref.watch(userBookmarksProvider.future);
  final savedIds = savedKeys
      .where((key) => key.startsWith('event:'))
      .map((key) => key.substring('event:'.length))
      .toList();

  if (savedIds.isEmpty) {
    return [];
  }

  final chunk = savedIds.take(20).toList();
  final response = await supabase
      .from('events')
      .select()
      .filter('id', 'in', chunk);

  final events = (response as List)
      .map((data) => EventModel.fromJson(data as Map<String, dynamic>))
      .toList();
  events.sort((a, b) => chunk.indexOf(a.id).compareTo(chunk.indexOf(b.id)));
  return events;
});

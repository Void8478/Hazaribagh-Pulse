import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/place_model.dart';
import '../../../../models/event_model.dart';
import '../services/supabase_bookmark_service.dart';
import '../repositories/bookmark_repository.dart';
import '../../../core/utils/mock_data.dart';
import '../../profile/providers/profile_providers.dart';

final bookmarkServiceProvider = Provider<SupabaseBookmarkService>((ref) {
  return SupabaseBookmarkService();
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final service = ref.watch(bookmarkServiceProvider);
  return BookmarkRepository(service);
});

// Fetch full Place objects based on saved place IDs
final savedPlacesProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final userProfile = await ref.watch(userProfileProvider.future);
  if (userProfile == null || userProfile.savedPlaceIds.isEmpty) {
    return [];
  }

  final chunk = userProfile.savedPlaceIds.take(10).toList();
  
  final response = await supabase
      .from('listings')
      .select()
      .filter('id', 'in', chunk);
      
  return (response as List).map((data) => PlaceModel.fromJson(data as Map<String, dynamic>)).toList();
});

// Fetch saved events — tries Supabase first, falls back to mock data
final savedEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final userProfile = await ref.watch(userProfileProvider.future);
  if (userProfile == null || userProfile.savedEventIds.isEmpty) {
    return [];
  }

  final savedIds = userProfile.savedEventIds;

  // Try Supabase first
  try {
    final chunk = savedIds.take(10).toList();
    final response = await supabase
        .from('events')
        .select()
        .filter('id', 'in', chunk);

    if (response.isNotEmpty) {
      return response.map((data) => EventModel.fromJson(data)).toList();
    }
  } catch (_) {
    // Supabase events collection may not exist yet — fall through to mock
  }

  // Fallback: filter mock events by saved IDs
  return MockData.mockEvents
      .where((e) => savedIds.contains(e.id))
      .toList();
});

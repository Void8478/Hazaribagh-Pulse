import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBookmarkService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> toggleSavedPlace(String userId, String placeId, bool isSaving) async {
    try {
      await _supabase.rpc('toggle_saved_place', params: {
        'user_id': userId,
        'place_id': placeId,
        'is_saving': isSaving
      });
    } catch (e) {
      throw Exception('Failed to toggle saved place: $e');
    }
  }

  Future<void> toggleSavedEvent(String userId, String eventId, bool isSaving) async {
    try {
      await _supabase.rpc('toggle_saved_event', params: {
        'user_id': userId,
        'event_id': eventId,
        'is_saving': isSaving
      });
    } catch (e) {
      throw Exception('Failed to toggle saved event: $e');
    }
  }
}

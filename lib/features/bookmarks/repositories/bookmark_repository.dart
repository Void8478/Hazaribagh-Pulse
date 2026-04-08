import '../services/supabase_bookmark_service.dart';

class BookmarkRepository {
  final SupabaseBookmarkService _service;

  BookmarkRepository(this._service);

  Future<void> toggleSavedPlace(String userId, String placeId, bool isSaving) {
    return _service.toggleSavedPlace(userId, placeId, isSaving);
  }

  Future<void> toggleSavedEvent(String userId, String eventId, bool isSaving) {
    return _service.toggleSavedEvent(userId, eventId, isSaving);
  }
}

import '../../../../models/event_model.dart';
import '../services/supabase_event_service.dart';

class EventRepository {
  final SupabaseEventService _service;

  EventRepository(this._service);

  Future<List<EventModel>> fetchUpcomingEvents({int? limit}) {
    return _service.getUpcomingEvents(limit: limit);
  }

  Future<EventModel> fetchEventById(String id) {
    return _service.getEventById(id);
  }
}

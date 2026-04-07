import '../../../../models/event_model.dart';
import '../services/firestore_event_service.dart';

class EventRepository {
  final FirestoreEventService _service;

  EventRepository(this._service);

  Future<List<EventModel>> fetchUpcomingEvents() {
    return _service.getUpcomingEvents();
  }

  Future<EventModel> fetchEventById(String id) {
    return _service.getEventById(id);
  }
}

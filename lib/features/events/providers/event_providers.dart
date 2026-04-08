import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/event_model.dart';
import '../services/supabase_event_service.dart';
import '../repositories/event_repository.dart';

final eventServiceProvider = Provider<SupabaseEventService>((ref) {
  return SupabaseEventService();
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final service = ref.watch(eventServiceProvider);
  return EventRepository(service);
});

final allEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.fetchUpcomingEvents();
});

final categoryEventsProvider = FutureProvider.family<List<EventModel>, String>((ref, category) async {
  final allEvents = await ref.watch(allEventsProvider.future);
  if (category == 'All') return allEvents;
  return allEvents.where((event) => event.category == category).toList();
});

final eventDetailProvider = FutureProvider.family<EventModel, String>((ref, id) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.fetchEventById(id);
});

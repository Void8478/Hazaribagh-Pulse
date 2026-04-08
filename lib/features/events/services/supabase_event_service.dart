import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/event_model.dart';

class SupabaseEventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      final List<dynamic> response = await _supabase
          .from('events')
          .select()
          .gte('date', DateTime.now().toIso8601String())
          .order('date', ascending: true);
      return response.map((data) => EventModel.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<EventModel> getEventById(String id) async {
    try {
      final data = await _supabase.from('events').select().eq('id', id).single();
      return EventModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch event details: $e');
    }
  }
}

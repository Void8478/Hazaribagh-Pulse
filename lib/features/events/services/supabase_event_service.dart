import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hazaribagh_pulse/models/event_model.dart';

class SupabaseEventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  Future<List<EventModel>> getUpcomingEvents({int? limit}) async {
    try {
      dynamic query = _supabase
          .from('events')
          .select()
          .gte('date', DateTime.now().toIso8601String())
          .order('date', ascending: true);
      if (limit != null) {
        query = query.limit(limit);
      }
      final List<dynamic> response = await query;
      return response.map((data) => EventModel.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<EventModel> getEventById(String id) async {
    try {
      final data = await _supabase
          .from('events')
          .select()
          .eq('id', _normalizedId(id))
          .single();
      return EventModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch event details: $e');
    }
  }
}

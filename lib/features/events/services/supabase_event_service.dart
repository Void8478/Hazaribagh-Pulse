import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hazaribagh_pulse/models/event_model.dart';

class SupabaseEventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByUserIds(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    final response = await _supabase
        .from('profiles')
        .select('id, full_name, username, avatar_url')
        .filter('id', 'in', ids);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return {
      for (final row in rows)
        if (row['id'] != null) row['id'].toString(): Map<String, dynamic>.from(row),
    };
  }

  Future<List<EventModel>> _mapEventsWithProfiles(
    List<Map<String, dynamic>> rows,
  ) async {
    final profilesById = await _fetchProfilesByUserIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final userId = row['user_id']?.toString() ?? '';
      merged['profiles'] = profilesById[userId];
      return EventModel.fromJson(merged);
    }).toList();
  }

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
      final response = await query;
      final rows = (response as List).cast<Map<String, dynamic>>();
      return _mapEventsWithProfiles(rows);
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<List<EventModel>> getEventsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      final rows = (response as List).cast<Map<String, dynamic>>();
      return _mapEventsWithProfiles(rows);
    } catch (e) {
      throw Exception('Failed to fetch user events: $e');
    }
  }

  Future<EventModel> getEventById(String id) async {
    try {
      final data = Map<String, dynamic>.from(await _supabase
          .from('events')
          .select()
          .eq('id', _normalizedId(id))
          .single());
      final profilesById = await _fetchProfilesByUserIds([
        data['user_id']?.toString() ?? '',
      ]);
      data['profiles'] = profilesById[data['user_id']?.toString() ?? ''];
      return EventModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch event details: $e');
    }
  }
}

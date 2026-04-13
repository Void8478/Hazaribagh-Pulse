import 'package:hazaribagh_pulse/models/event_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  Future<Map<String, String>> _fetchActiveCategoryNamesById() async {
    final response = await _supabase
        .from('categories')
        .select('id, name')
        .eq('is_active', true)
        .order('manual_rank', ascending: true)
        .order('name', ascending: true);
    final rows = (response as List).cast<Map<String, dynamic>>();

    return {
      for (final row in rows)
        if (row['id'] != null) row['id'].toString(): (row['name'] ?? 'Category').toString(),
    };
  }

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
    final categoryNamesById = await _fetchActiveCategoryNamesById();
    final profilesById = await _fetchProfilesByUserIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    final events = rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final userId = row['user_id']?.toString() ?? '';
      final categoryId = row['category_id']?.toString();
      if ((merged['category'] == null || merged['category'].toString().trim().isEmpty) &&
          categoryId != null &&
          categoryNamesById.containsKey(categoryId)) {
        merged['category'] = categoryNamesById[categoryId];
      }
      merged['profiles'] = profilesById[userId];
      return EventModel.fromJson(merged);
    }).toList();

    events.sort((a, b) {
      final featuredCompare = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
      if (featuredCompare != 0) return featuredCompare;
      final rankCompare = a.manualRank.compareTo(b.manualRank);
      if (rankCompare != 0) return rankCompare;
      return a.sortDate.compareTo(b.sortDate);
    });

    return events;
  }

  Future<List<EventModel>> _fetchEvents({
    int? limit,
    bool upcomingOnly = false,
  }) async {
    dynamic query = _supabase.from('events').select().eq('status', 'active');

    if (upcomingOnly) {
      query = query.gte('start_date', DateTime.now().toUtc().toIso8601String());
    }

    query = query
        .order('is_featured', ascending: false)
        .order('manual_rank', ascending: true)
        .order('start_date', ascending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    final rows = (response as List).cast<Map<String, dynamic>>();
    return _mapEventsWithProfiles(rows);
  }

  Future<List<EventModel>> getAllActiveEvents({int? limit}) async {
    return _fetchEvents(limit: limit);
  }

  Future<List<EventModel>> getUpcomingEvents({int? limit}) async {
    return _fetchEvents(limit: limit, upcomingOnly: true);
  }

  Future<List<EventModel>> getEventsByUserId(String userId) async {
    final response = await _supabase
        .from('events')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('is_featured', ascending: false)
        .order('manual_rank', ascending: true)
        .order('start_date', ascending: true);
    final rows = (response as List).cast<Map<String, dynamic>>();
    return _mapEventsWithProfiles(rows);
  }

  Future<EventModel> getEventById(String id) async {
    final data = Map<String, dynamic>.from(
      await _supabase
          .from('events')
          .select()
          .eq('id', _normalizedId(id))
          .eq('status', 'active')
          .single(),
    );
    final categoryNamesById = await _fetchActiveCategoryNamesById();
    final profilesById = await _fetchProfilesByUserIds([
      data['user_id']?.toString() ?? '',
    ]);
    final categoryId = data['category_id']?.toString();
    if ((data['category'] == null || data['category'].toString().trim().isEmpty) &&
        categoryId != null &&
        categoryNamesById.containsKey(categoryId)) {
      data['category'] = categoryNamesById[categoryId];
    }
    data['profiles'] = profilesById[data['user_id']?.toString() ?? ''];
    return EventModel.fromJson(data);
  }
}

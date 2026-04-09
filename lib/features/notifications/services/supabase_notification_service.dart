import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/app_notification_model.dart';

class SupabaseNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
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

  Stream<List<AppNotificationModel>> watchCurrentUserNotifications() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return Stream.value(const <AppNotificationModel>[]);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_user_id', currentUser.id)
        .asyncMap((rows) async {
          final notifications = rows.cast<Map<String, dynamic>>();
          final profilesById = await _fetchProfilesByIds(
            notifications.map((row) => row['actor_user_id']?.toString() ?? ''),
          );

          final mapped = notifications.map((row) {
            final merged = Map<String, dynamic>.from(row);
            merged['actor_profile'] =
                profilesById[row['actor_user_id']?.toString() ?? ''];
            return AppNotificationModel.fromJson(merged);
          }).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return mapped;
        });
  }

  Future<void> markAsRead(String notificationId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('recipient_user_id', currentUser.id);
  }

  Future<void> markAllAsRead() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_user_id', currentUser.id)
        .eq('is_read', false);
  }
}

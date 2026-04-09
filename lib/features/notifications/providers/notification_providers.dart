import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_notification_model.dart';
import '../../auth/services/auth_provider.dart';
import '../services/supabase_notification_service.dart';

final notificationServiceProvider = Provider<SupabaseNotificationService>((ref) {
  return SupabaseNotificationService();
});

final notificationsProvider = StreamProvider<List<AppNotificationModel>>((ref) {
  final currentUser = ref.watch(authProvider.select((value) => value.user));
  if (currentUser == null) {
    return Stream.value(const <AppNotificationModel>[]);
  }

  return ref.watch(notificationServiceProvider).watchCurrentUserNotifications();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  final notifications = notificationsAsync.maybeWhen(
    data: (items) => items,
    orElse: () => const <AppNotificationModel>[],
  );
  return notifications.where((notification) => !notification.isRead).length;
});

import 'public_author_model.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.recipientUserId,
    required this.actorUserId,
    required this.type,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.actor,
  });

  final String id;
  final String recipientUserId;
  final String actorUserId;
  final String type;
  final String contentId;
  final String contentType;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final PublicAuthorModel actor;

  factory AppNotificationModel.fromJson(Map<String, dynamic> data) {
    final actorMap =
        data['actor_profile'] is Map<String, dynamic>
            ? data['actor_profile'] as Map<String, dynamic>
            : data['actor_profile'] is Map
                ? Map<String, dynamic>.from(data['actor_profile'] as Map)
                : null;

    return AppNotificationModel(
      id: data['id']?.toString() ?? '',
      recipientUserId: data['recipient_user_id']?.toString() ?? '',
      actorUserId: data['actor_user_id']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      contentId: data['content_id']?.toString() ?? '',
      contentType: data['content_type']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      isRead: data['is_read'] == true,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actor: PublicAuthorModel.fromProfile(
        actorMap,
        fallbackId: data['actor_user_id']?.toString() ?? '',
      ),
    );
  }
}

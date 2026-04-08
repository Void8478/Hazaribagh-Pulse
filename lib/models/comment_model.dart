class CommentModel {
  const CommentModel({
    required this.id,
    required this.contentId,
    required this.userId,
    required this.authorName,
    this.authorUsername = '',
    this.authorAvatarUrl = '',
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String contentId;
  final String userId;
  final String authorName;
  final String authorUsername;
  final String authorAvatarUrl;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory CommentModel.fromJson(
    Map<String, dynamic> data, {
    required String contentIdKey,
  }) {
    final profileMap =
        data['profiles'] is Map<String, dynamic>
            ? data['profiles'] as Map<String, dynamic>
            : data['profiles'] is Map
                ? Map<String, dynamic>.from(data['profiles'] as Map)
                : null;

    final fullName = (profileMap?['full_name'] ?? '').toString().trim();
    final username = (profileMap?['username'] ?? '').toString().trim();
    final createdAtValue =
        data['created_at'] ?? data['timestamp'] ?? data['inserted_at'];

    return CommentModel(
      id: data['id']?.toString() ?? '',
      contentId: data[contentIdKey]?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      authorName: fullName.isNotEmpty
          ? fullName
          : (username.isNotEmpty ? '@$username' : 'Anonymous'),
      authorUsername: username,
      authorAvatarUrl: (profileMap?['avatar_url'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: createdAtValue != null
          ? DateTime.tryParse(createdAtValue.toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }
}

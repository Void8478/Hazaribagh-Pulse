class PublicAuthorModel {
  const PublicAuthorModel({
    required this.id,
    required this.fullName,
    this.username = '',
    this.avatarUrl = '',
  });

  final String id;
  final String fullName;
  final String username;
  final String avatarUrl;

  String get displayName => fullName.trim().isNotEmpty ? fullName : 'User';

  String get usernameLabel => username.trim().isNotEmpty ? '@$username' : '';

  factory PublicAuthorModel.fromProfile(Map<String, dynamic>? data, {String fallbackId = ''}) {
    final profile = data ?? const <String, dynamic>{};
    return PublicAuthorModel(
      id: profile['id']?.toString() ?? fallbackId,
      fullName: profile['full_name']?.toString().trim().isNotEmpty == true
          ? profile['full_name'].toString().trim()
          : 'User',
      username: profile['username']?.toString().trim() ?? '',
      avatarUrl: profile['avatar_url']?.toString().trim() ?? '',
    );
  }
}

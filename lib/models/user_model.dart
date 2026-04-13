class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String bio;
  final String location;
  final String email;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String avatarUrl;
  final int reviewsCount;
  final int photosCount;
  final List<String> savedPlaceIds;
  final List<String> savedEventIds;

  String get name => fullName;

  UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.bio,
    required this.location,
    required this.email,
    this.isAdmin = false,
    this.createdAt,
    this.updatedAt,
    required this.avatarUrl,
    required this.reviewsCount,
    required this.photosCount,
    required this.savedPlaceIds,
    required this.savedEventIds,
  });

  factory UserModel.fromProfile(
    Map<String, dynamic> data, {
    String email = '',
  }) {
    return UserModel(
      id: data['id']?.toString() ?? '',
      fullName: data['full_name']?.toString().trim().isNotEmpty == true
          ? data['full_name'].toString()
          : 'User',
      username: data['username']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      email: email,
      isAdmin: data['is_admin'] == true || data['isAdmin'] == true,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
      avatarUrl: data['avatar_url']?.toString() ?? '',
      reviewsCount: data['reviews_count'] ?? data['reviewsCount'] ?? 0,
      photosCount: data['photos_count'] ?? data['photosCount'] ?? 0,
      savedPlaceIds: List<String>.from(
        data['saved_place_ids'] ?? data['savedPlaceIds'] ?? const [],
      ),
      savedEventIds: List<String>.from(
        data['saved_event_ids'] ?? data['savedEventIds'] ?? const [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'location': location,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

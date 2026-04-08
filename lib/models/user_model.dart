class UserModel {
  final String id;
  final String fullName; // Changed from 'name', but we can keep getters backwards compatible if needed
  final String email;
  final String phoneNumber;
  final String authProvider;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String avatarUrl;
  final String trustLevel;
  final int points;
  final int reviewsCount;
  final int photosCount;
  final List<String> savedPlaceIds;
  final List<String> savedEventIds;

  // Backwards compatibility getter just in case
  String get name => fullName;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.authProvider,
    this.createdAt,
    this.updatedAt,
    required this.avatarUrl,
    required this.trustLevel,
    required this.points,
    required this.reviewsCount,
    required this.photosCount,
    required this.savedPlaceIds,
    required this.savedEventIds,
  });

  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
      id: data['id']?.toString() ?? '',
      fullName: data['full_name'] ?? data['fullName'] ?? data['name'] ?? 'User',
      email: data['email'] ?? '',
      phoneNumber: data['phone_number'] ?? data['phoneNumber'] ?? '',
      authProvider: data['auth_provider'] ?? data['authProvider'] ?? 'unknown',
      createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) : null,
      updatedAt: data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null,
      avatarUrl: data['avatar_url'] ?? data['avatarUrl'] ?? '',
      trustLevel: data['trust_level'] ?? data['trustLevel'] ?? 'Newcomer',
      points: data['points'] ?? 0,
      reviewsCount: data['reviews_count'] ?? data['reviewsCount'] ?? 0,
      photosCount: data['photos_count'] ?? data['photosCount'] ?? 0,
      savedPlaceIds: List<String>.from(data['saved_place_ids'] ?? data['savedPlaceIds'] ?? []),
      savedEventIds: List<String>.from(data['saved_event_ids'] ?? data['savedEventIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'trust_level': trustLevel,
      'points': points,
      'reviews_count': reviewsCount,
      'photos_count': photosCount,
      'saved_place_ids': savedPlaceIds,
      'saved_event_ids': savedEventIds,
    };
  }
}


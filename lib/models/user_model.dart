import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? data['name'] ?? 'User',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      authProvider: data['authProvider'] ?? 'unknown',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      avatarUrl: data['avatarUrl'] ?? '',
      trustLevel: data['trustLevel'] ?? 'Newcomer',
      points: data['points'] ?? 0,
      reviewsCount: data['reviewsCount'] ?? 0,
      photosCount: data['photosCount'] ?? 0,
      savedPlaceIds: List<String>.from(data['savedPlaceIds'] ?? []),
      savedEventIds: List<String>.from(data['savedEventIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'authProvider': authProvider,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'avatarUrl': avatarUrl,
      'trustLevel': trustLevel,
      'points': points,
      'reviewsCount': reviewsCount,
      'photosCount': photosCount,
      'savedPlaceIds': savedPlaceIds,
      'savedEventIds': savedEventIds,
      // Optional mapping back to name for legacy querying
      'name': fullName,
    };
  }
}


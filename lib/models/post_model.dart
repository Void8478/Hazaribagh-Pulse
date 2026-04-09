import 'public_author_model.dart';

class PostModel {
  final String id;
  final String userId;
  final PublicAuthorModel creator;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final String categoryId;
  final String categoryName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.creator,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.categoryId,
    required this.categoryName,
    this.createdAt,
    this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> data) {
    final categoryMap =
        data['categories'] is Map<String, dynamic>
            ? data['categories'] as Map<String, dynamic>
            : data['categories'] is Map
                ? Map<String, dynamic>.from(data['categories'] as Map)
                : null;

    final profileMap =
        data['profiles'] is Map<String, dynamic>
            ? data['profiles'] as Map<String, dynamic>
            : data['profiles'] is Map
                ? Map<String, dynamic>.from(data['profiles'] as Map)
                : null;
    final userId = data['user_id']?.toString() ?? '';

    return PostModel(
      id: data['id']?.toString() ?? '',
      userId: userId,
      creator: PublicAuthorModel.fromProfile(profileMap, fallbackId: userId),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['image_url'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      categoryId:
          (data['category_id'] ?? categoryMap?['id'] ?? '').toString(),
      categoryName:
          (data['category_name'] ?? categoryMap?['name'] ?? '').toString(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }
}

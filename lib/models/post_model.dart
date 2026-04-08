class PostModel {
  final String id;
  final String userId;
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

    return PostModel(
      id: data['id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
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

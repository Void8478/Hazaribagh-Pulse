import 'public_author_model.dart';

class PlaceModel {
  final String id;
  final String userId;
  final PublicAuthorModel creator;
  final String name;
  final String categoryId;
  final String category;
  final String imageUrl;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final String location;
  final double rating;
  final int reviewCount;
  final bool isSponsored;
  final bool isVerified;
  
  // New fields for details
  final String address;
  final String phone;
  final String openingHours;
  final String priceRange; // e.g., "$$"
  final String description;

  const PlaceModel({
    required this.id,
    this.userId = '',
    this.creator = const PublicAuthorModel(id: '', fullName: 'User'),
    required this.name,
    this.categoryId = '',
    required this.category,
    required this.imageUrl,
    this.imageUrls = const [],
    this.createdAt,
    this.location = '',
    required this.rating,
    required this.reviewCount,
    this.isSponsored = false,
    this.isVerified = false,
    this.address = '',
    this.phone = '',
    this.openingHours = '9:00 AM - 5:00 PM',
    this.priceRange = '₹₹',
    this.description = 'A wonderful place in Hazaribagh.',
  });

  factory PlaceModel.fromJson(Map<String, dynamic> data) {
    final categoryMap =
        data['categories'] is Map
            ? Map<String, dynamic>.from(data['categories'] as Map)
            : null;
    final categoryName =
        data['category'] ??
        data['category_name'] ??
        categoryMap?['name'] ??
        'Uncategorized';
    final imageUrl =
        data['image_url'] ??
        data['cover_image_url'] ??
        data['thumbnail_url'] ??
        data['imageUrl'] ??
        'https://via.placeholder.com/500';

    final profileMap =
        data['profiles'] is Map<String, dynamic>
            ? data['profiles'] as Map<String, dynamic>
            : data['profiles'] is Map
                ? Map<String, dynamic>.from(data['profiles'] as Map)
                : null;
    final userId = data['user_id']?.toString() ?? '';

    return PlaceModel(
      id: data['id']?.toString() ?? '',
      userId: userId,
      creator: PublicAuthorModel.fromProfile(profileMap, fallbackId: userId),
      name: data['name'] ?? data['title'] ?? 'Unknown Place',
      categoryId:
          data['category_id']?.toString() ??
          categoryMap?['id']?.toString() ??
          '',
      category: categoryName.toString(),
      imageUrl: imageUrl.toString(),
      imageUrls: List<String>.from(data['image_urls'] ?? data['imageUrls'] ?? []),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      location: (data['location'] ?? data['location_label'] ?? '').toString(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['review_count'] ?? data['reviewCount'] ?? 0,
      isSponsored: data['is_sponsored'] ?? data['isSponsored'] ?? false,
      isVerified: data['is_verified'] ?? data['isVerified'] ?? false,
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      openingHours: data['opening_hours'] ?? data['openingHours'] ?? '9:00 AM - 5:00 PM',
      priceRange: data['price_range'] ?? data['priceRange'] ?? '₹₹',
      description: data['description'] ?? 'A wonderful place in Hazaribagh.',
    );
  }
}

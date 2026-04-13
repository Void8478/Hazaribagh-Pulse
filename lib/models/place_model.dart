import 'public_author_model.dart';
import '../core/utils/content_display.dart';

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
  final bool isFeatured;
  final int manualRank;
  final String status;
  final String address;
  final String city;
  final String area;
  final String phone;
  final String openingHours;
  final String priceRange;
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
    this.isFeatured = false,
    this.manualRank = 0,
    this.status = 'active',
    this.address = '',
    this.city = '',
    this.area = '',
    this.phone = '',
    this.openingHours = '',
    this.priceRange = '',
    this.description = '',
  });

  factory PlaceModel.fromJson(Map<String, dynamic> data) {
    final categoryMap = data['categories'] is Map
        ? Map<String, dynamic>.from(data['categories'] as Map)
        : null;
    final categoryName =
        data['category'] ?? data['category_name'] ?? categoryMap?['name'] ?? 'Uncategorized';
    final imageUrl = firstNonEmpty([
      data['image_url']?.toString(),
      data['cover_image_url']?.toString(),
      data['thumbnail_url']?.toString(),
      data['imageUrl']?.toString(),
    ]);

    final profileMap = data['profiles'] is Map<String, dynamic>
        ? data['profiles'] as Map<String, dynamic>
        : data['profiles'] is Map
            ? Map<String, dynamic>.from(data['profiles'] as Map)
            : null;
    final userId = data['user_id']?.toString() ?? '';

    return PlaceModel(
      id: data['id']?.toString() ?? '',
      userId: userId,
      creator: PublicAuthorModel.fromProfile(profileMap, fallbackId: userId),
      name: firstNonEmpty([
        data['name']?.toString(),
        data['title']?.toString(),
        'Untitled place',
      ]),
      categoryId: data['category_id']?.toString() ?? categoryMap?['id']?.toString() ?? '',
      category: categoryName.toString(),
      imageUrl: imageUrl.toString(),
      imageUrls: (data['image_urls'] as List? ?? data['imageUrls'] as List? ?? const [])
          .map((item) => item?.toString() ?? '')
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      location: (data['location'] ??
              data['location_label'] ??
              data['city'] ??
              data['area'] ??
              '')
          .toString(),
      rating: _parseDouble(
        data['rating'] ?? data['avg_rating'] ?? data['average_rating'],
      ),
      reviewCount: _parseInt(
        data['total_reviews'] ?? data['review_count'] ?? data['reviewCount'],
      ),
      isSponsored: data['is_sponsored'] ?? data['isSponsored'] ?? false,
      isVerified: data['is_verified'] ?? data['isVerified'] ?? false,
      isFeatured: data['is_featured'] ?? data['isFeatured'] ?? false,
      manualRank: int.tryParse((data['manual_rank'] ?? 0).toString()) ?? 0,
      status: (data['status'] ?? 'active').toString(),
      address: (data['address'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      area: (data['area'] ?? '').toString(),
      phone: (data['phone_number'] ?? data['phone'] ?? '').toString(),
      openingHours: (data['opening_hours'] ?? data['openingHours'] ?? '').toString(),
      priceRange: (data['price_range'] ?? data['priceRange'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
    );
  }

  bool get hasImage => primaryImageUrl.isNotEmpty;

  String get primaryImageUrl {
    return firstNonEmpty([imageUrl, ...imageUrls]);
  }

  String get categoryLabel =>
      category.trim().isEmpty ? 'Uncategorized' : category.trim();

  String get locationLabel {
    return firstNonEmpty([
      joinNonEmpty([area, city]),
      address,
      location,
      city,
      area,
    ]);
  }

  String get fullAddressLabel {
    return firstNonEmpty([
      joinNonEmpty([address, area, city]),
      location,
      joinNonEmpty([area, city]),
      address,
    ]);
  }

  bool get hasRating => rating > 0;

  String get descriptionLabel => description.trim().isEmpty
      ? 'Description will be added soon.'
      : description.trim();

  String get phoneLabel =>
      phone.trim().isEmpty ? 'Phone not available' : phone.trim();

  String get openingHoursLabel => openingHours.trim().isEmpty
      ? 'Hours not available'
      : openingHours.trim();
}

double _parseDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _parseInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class PlaceModel {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final List<String> imageUrls;
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
    required this.name,
    required this.category,
    required this.imageUrl,
    this.imageUrls = const [],
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
    return PlaceModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? 'Unknown Place',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? 'https://via.placeholder.com/500',
      imageUrls: List<String>.from(data['image_urls'] ?? data['imageUrls'] ?? []),
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

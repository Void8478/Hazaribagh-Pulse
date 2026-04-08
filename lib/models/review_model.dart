class ReviewModel {
  final String id;
  final String listingId;
  final String userId;
  final String authorName;
  final String authorUsername;
  final String authorImageUrl;
  final double rating;
  final String text;
  final DateTime timestamp;
  
  // Advanced fields
  final String pros;
  final String cons;
  final String pricingTip;
  final String bestTimeToVisit;
  final List<String> imageUrls;

  const ReviewModel({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.authorName,
    this.authorUsername = '',
    this.authorImageUrl = '',
    required this.rating,
    required this.text,
    required this.timestamp,
    this.pros = '',
    this.cons = '',
    this.pricingTip = '',
    this.bestTimeToVisit = '',
    this.imageUrls = const [],
  });

  factory ReviewModel.fromJson(Map<String, dynamic> data) {
    final profileMap =
        data['profiles'] is Map<String, dynamic>
            ? data['profiles'] as Map<String, dynamic>
            : data['profiles'] is Map
                ? Map<String, dynamic>.from(data['profiles'] as Map)
                : null;
    final fullName = (profileMap?['full_name'] ?? '').toString().trim();
    final username = (profileMap?['username'] ?? '').toString().trim();

    DateTime parsedTimestamp;
    final timestampValue = data['created_at'] ?? data['timestamp'];
    if (timestampValue != null) {
      parsedTimestamp =
          DateTime.tryParse(timestampValue.toString()) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ReviewModel(
      id: data['id']?.toString() ?? '',
      listingId: data['listing_id']?.toString() ?? data['listingId']?.toString() ?? '',
      userId: data['user_id']?.toString() ??
          data['author_id']?.toString() ??
          data['userId']?.toString() ??
          data['authorId']?.toString() ??
          '',
      authorName: fullName.isNotEmpty
          ? fullName
          : (data['author_name'] ??
                  data['authorName'] ??
                  (username.isNotEmpty ? '@$username' : 'Anonymous'))
              .toString(),
      authorUsername: username,
      authorImageUrl: (profileMap?['avatar_url'] ??
              data['author_image_url'] ??
              data['authorImageUrl'] ??
              '')
          .toString(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      text: (data['text'] ?? '').toString(),
      timestamp: parsedTimestamp,
      pros: (data['pros'] ?? '').toString(),
      cons: (data['cons'] ?? '').toString(),
      pricingTip: (data['pricing_tip'] ?? data['pricingTip'] ?? '').toString(),
      bestTimeToVisit: (data['best_time_to_visit'] ?? data['bestTimeToVisit'] ?? '').toString(),
      imageUrls: List<String>.from(data['image_urls'] ?? data['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listing_id': listingId,
      'user_id': userId,
      'rating': rating,
      'text': text,
      'created_at': timestamp.toIso8601String(),
      'updated_at': timestamp.toIso8601String(),
      'pros': pros,
      'cons': cons,
      'pricing_tip': pricingTip,
      'best_time_to_visit': bestTimeToVisit,
      'image_urls': imageUrls,
    };
  }
}

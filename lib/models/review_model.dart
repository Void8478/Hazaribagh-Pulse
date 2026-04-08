class ReviewModel {
  final String id;
  final String listingId;
  final String authorId;
  final String authorName;
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
    required this.authorId,
    required this.authorName,
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
    DateTime parsedTimestamp;
    if (data['timestamp'] != null) {
      parsedTimestamp = DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ReviewModel(
      id: data['id']?.toString() ?? '',
      listingId: data['listing_id']?.toString() ?? data['listingId']?.toString() ?? '',
      authorId: data['author_id']?.toString() ?? data['authorId']?.toString() ?? '',
      authorName: data['author_name'] ?? data['authorName'] ?? 'Anonymous',
      authorImageUrl: data['author_image_url'] ?? data['authorImageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      text: data['text'] ?? '',
      timestamp: parsedTimestamp,
      pros: data['pros'] ?? '',
      cons: data['cons'] ?? '',
      pricingTip: data['pricing_tip'] ?? data['pricingTip'] ?? '',
      bestTimeToVisit: data['best_time_to_visit'] ?? data['bestTimeToVisit'] ?? '',
      imageUrls: List<String>.from(data['image_urls'] ?? data['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listing_id': listingId,
      'author_id': authorId,
      'author_name': authorName,
      'author_image_url': authorImageUrl,
      'rating': rating,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'pros': pros,
      'cons': cons,
      'pricing_tip': pricingTip,
      'best_time_to_visit': bestTimeToVisit,
      'image_urls': imageUrls,
    };
  }
}


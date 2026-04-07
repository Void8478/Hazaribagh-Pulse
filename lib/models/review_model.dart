import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    DateTime parsedTimestamp;
    if (data['timestamp'] is Timestamp) {
      parsedTimestamp = (data['timestamp'] as Timestamp).toDate();
    } else {
      parsedTimestamp = DateTime.now(); // Fallback
    }

    return ReviewModel(
      id: doc.id,
      listingId: data['listingId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorImageUrl: data['authorImageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      text: data['text'] ?? '',
      timestamp: parsedTimestamp,
      pros: data['pros'] ?? '',
      cons: data['cons'] ?? '',
      pricingTip: data['pricingTip'] ?? '',
      bestTimeToVisit: data['bestTimeToVisit'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'authorId': authorId,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'rating': rating,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'pros': pros,
      'cons': cons,
      'pricingTip': pricingTip,
      'bestTimeToVisit': bestTimeToVisit,
      'imageUrls': imageUrls,
    };
  }
}


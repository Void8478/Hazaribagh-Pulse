import 'public_author_model.dart';
import '../core/utils/content_display.dart';

class EventModel {
  final String id;
  final String userId;
  final PublicAuthorModel creator;
  final String title;
  final String categoryId;
  final String category;
  final String imageUrl;
  final String organizer;
  final String location;
  final String address;
  final String city;
  final String area;
  final DateTime startDate;
  final bool hasStartDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final String time;
  final bool isFree;
  final bool isFeatured;
  final int manualRank;
  final String status;
  final String price;
  final String description;

  const EventModel({
    required this.id,
    this.userId = '',
    this.creator = const PublicAuthorModel(id: '', fullName: 'User'),
    required this.title,
    this.categoryId = '',
    required this.category,
    required this.imageUrl,
    required this.organizer,
    required this.location,
    required this.address,
    required this.startDate,
    this.hasStartDate = true,
    this.endDate,
    this.city = '',
    this.area = '',
    this.createdAt,
    required this.time,
    this.isFree = false,
    this.isFeatured = false,
    this.manualRank = 0,
    this.status = 'active',
    this.price = '',
    required this.description,
  });

  factory EventModel.fromJson(Map<String, dynamic> data) {
    final rawStartDate = data['start_date'] ?? data['date'];
    final parsedStartDate = rawStartDate != null
        ? DateTime.tryParse(rawStartDate.toString())
        : null;
    final parsedEndDate = data['end_date'] != null
        ? DateTime.tryParse(data['end_date'].toString())
        : null;
    final categoryMap = data['categories'] is Map<String, dynamic>
        ? data['categories'] as Map<String, dynamic>
        : data['categories'] is Map
            ? Map<String, dynamic>.from(data['categories'] as Map)
            : null;

    final profileMap = data['profiles'] is Map<String, dynamic>
        ? data['profiles'] as Map<String, dynamic>
        : data['profiles'] is Map
            ? Map<String, dynamic>.from(data['profiles'] as Map)
            : null;
    final userId = data['user_id']?.toString() ?? '';

    return EventModel(
      id: data['id']?.toString() ?? '',
      userId: userId,
      creator: PublicAuthorModel.fromProfile(profileMap, fallbackId: userId),
      title: firstNonEmpty([
        data['title']?.toString(),
        data['name']?.toString(),
        'Untitled event',
      ]),
      categoryId: (data['category_id'] ?? categoryMap?['id'] ?? '').toString(),
      category: firstNonEmpty([
        data['category']?.toString(),
        data['category_name']?.toString(),
        categoryMap?['name']?.toString(),
        'Event',
      ]),
      imageUrl: firstNonEmpty([
        data['image_url']?.toString(),
        data['imageUrl']?.toString(),
      ]),
      organizer: (data['organizer'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      area: (data['area'] ?? '').toString(),
      startDate: parsedStartDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      hasStartDate: parsedStartDate != null,
      endDate: parsedEndDate,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      time: (data['time'] ?? '').toString(),
      isFree: data['is_free'] ?? data['isFree'] ?? false,
      isFeatured: data['is_featured'] ?? data['isFeatured'] ?? false,
      manualRank: int.tryParse((data['manual_rank'] ?? 0).toString()) ?? 0,
      status: (data['status'] ?? 'active').toString(),
      price: (data['price'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
    );
  }

  DateTime get date => startDate;

  DateTime? get startDateOrNull => hasStartDate ? startDate : null;

  DateTime get sortDate => hasStartDate
      ? startDate
      : DateTime(9999);

  String get categoryLabel =>
      category.trim().isEmpty ? 'Event' : category.trim();

  String get locationLabel {
    return firstNonEmpty([
      location,
      joinNonEmpty([area, city]),
      address,
      city,
      area,
    ]);
  }

  String get fullLocationLabel {
    return firstNonEmpty([
      joinNonEmpty([location, address, area, city]),
      joinNonEmpty([location, area, city]),
      joinNonEmpty([address, area, city]),
      location,
    ]);
  }

  String get descriptionLabel => description.trim().isEmpty
      ? 'Event details will be added soon.'
      : description.trim();

  String get organizerLabel => organizer.trim().isEmpty
      ? 'Organizer to be announced'
      : organizer.trim();

  String get timeLabel => time.trim().isEmpty ? 'Time TBA' : time.trim();

  String get priceLabel {
    if (isFree) return 'Free entry';
    if (price.trim().isEmpty) return 'Price on request';
    return price.trim();
  }

  bool get isUpcoming => hasStartDate && startDate.isAfter(DateTime.now());
}

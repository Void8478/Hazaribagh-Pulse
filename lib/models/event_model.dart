import 'public_author_model.dart';

class EventModel {
  final String id;
  final String userId;
  final PublicAuthorModel creator;
  final String title;
  final String category;
  final String imageUrl;
  final String organizer;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final bool isFree;
  final String price;
  final String description;

  const EventModel({
    required this.id,
    this.userId = '',
    this.creator = const PublicAuthorModel(id: '', fullName: 'User'),
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.organizer,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    this.isFree = false,
    this.price = '',
    required this.description,
  });

  factory EventModel.fromJson(Map<String, dynamic> data) {
    DateTime parsedDate;
    if (data['date'] != null) {
      parsedDate = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final profileMap =
        data['profiles'] is Map<String, dynamic>
            ? data['profiles'] as Map<String, dynamic>
            : data['profiles'] is Map
                ? Map<String, dynamic>.from(data['profiles'] as Map)
                : null;
    final userId = data['user_id']?.toString() ?? '';

    return EventModel(
      id: data['id']?.toString() ?? '',
      userId: userId,
      creator: PublicAuthorModel.fromProfile(profileMap, fallbackId: userId),
      title: data['title'] ?? 'Unknown Event',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? 'https://via.placeholder.com/800',
      organizer: data['organizer'] ?? 'Unknown Organizer',
      location: data['location'] ?? 'Location TBA',
      address: data['address'] ?? '',
      date: parsedDate,
      time: data['time'] ?? 'Time TBA',
      isFree: data['is_free'] ?? data['isFree'] ?? false,
      price: data['price'] ?? '',
      description: data['description'] ?? 'No description provided.',
    );
  }
}

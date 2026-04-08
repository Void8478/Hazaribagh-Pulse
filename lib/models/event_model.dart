class EventModel {
  final String id;
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

    return EventModel(
      id: data['id']?.toString() ?? '',
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

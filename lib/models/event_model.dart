import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    DateTime parsedDate;
    if (data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now(); // Fallback
    }

    return EventModel(
      id: doc.id,
      title: data['title'] ?? 'Unknown Event',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/800',
      organizer: data['organizer'] ?? 'Unknown Organizer',
      location: data['location'] ?? 'Location TBA',
      address: data['address'] ?? '',
      date: parsedDate,
      time: data['time'] ?? 'Time TBA',
      isFree: data['isFree'] ?? false,
      price: data['price'] ?? '',
      description: data['description'] ?? 'No description provided.',
    );
  }
}

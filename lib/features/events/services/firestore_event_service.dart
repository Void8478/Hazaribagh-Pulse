import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/event_model.dart';

class FirestoreEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      // Typically we would filter where date >= DateTime.now()
      // For local prototype matching, we pull all from the 'events' collection
      final snapshot = await _firestore.collection('events').get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<EventModel> getEventById(String id) async {
    try {
      final doc = await _firestore.collection('events').doc(id).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      } else {
        throw Exception('Event not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch event details: $e');
    }
  }
}

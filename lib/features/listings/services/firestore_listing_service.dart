import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/place_model.dart';

class FirestoreListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PlaceModel>> getAllListings() async {
    try {
      final snapshot = await _firestore.collection('places').get();
      return snapshot.docs.map((doc) => PlaceModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  Future<PlaceModel> getListingById(String id) async {
    try {
      final doc = await _firestore.collection('places').doc(id).get();
      if (doc.exists) {
        return PlaceModel.fromFirestore(doc);
      } else {
        throw Exception('Listing not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch listing details: $e');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/place_model.dart';

class SupabaseListingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PlaceModel>> getAllListings() async {
    try {
      final List<dynamic> response = await _supabase.from('places').select();
      return response.map((data) => PlaceModel.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  Future<PlaceModel> getListingById(String id) async {
    try {
      final data = await _supabase.from('places').select().eq('id', id).single();
      return PlaceModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch listing details: $e');
    }
  }
}

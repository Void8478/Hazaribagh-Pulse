import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseContentCreationService {
  SupabaseContentCreationService(this._supabase);

  final SupabaseClient _supabase;

  Object? _normalizedIntId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed) ?? trimmed;
  }

  User get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to create content.');
    }
    return user;
  }

  Future<void> createPost({
    required String title,
    required String description,
    required String categoryId,
    required String location,
    String imageUrl = '',
  }) async {
    final user = currentUser;

    await _supabase.from('posts').insert({
      'user_id': user.id,
      'title': title.trim(),
      'description': description.trim(),
      'category_id': _normalizedIntId(categoryId),
      'location': location.trim().isEmpty ? null : location.trim(),
      'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
    });
  }

  Future<void> createListing({
    required String title,
    required String description,
    required String categoryId,
    required String address,
    required String locationLabel,
    String imageUrl = '',
    String phone = '',
    String openingHours = '',
    String priceRange = '',
  }) async {
    final user = currentUser;
    final trimmedTitle = title.trim();
    final trimmedAddress = address.trim();

    await _supabase.from('listings').insert({
      'user_id': user.id,
      'title': trimmedTitle,
      'name': trimmedTitle,
      'description': description.trim(),
      'category_id': _normalizedIntId(categoryId),
      'address': trimmedAddress,
      'location': locationLabel.trim().isEmpty ? trimmedAddress : locationLabel.trim(),
      'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
      'image_urls': imageUrl.trim().isEmpty ? <String>[] : <String>[imageUrl.trim()],
      'phone': phone.trim().isEmpty ? null : phone.trim(),
      'opening_hours':
          openingHours.trim().isEmpty ? null : openingHours.trim(),
      'price_range': priceRange.trim().isEmpty ? null : priceRange.trim(),
      'rating': 0,
      'review_count': 0,
      'is_sponsored': false,
      'is_verified': false,
    });
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required String categoryId,
    required String categoryName,
    required String location,
    required DateTime date,
    required String time,
    String imageUrl = '',
    String organizer = '',
    String address = '',
    bool isFree = true,
    String price = '',
  }) async {
    final user = currentUser;

    await _supabase.from('events').insert({
      'user_id': user.id,
      'title': title.trim(),
      'description': description.trim(),
      'category_id': _normalizedIntId(categoryId),
      'category': categoryName.trim().isEmpty ? null : categoryName.trim(),
      'location': location.trim(),
      'address': address.trim().isEmpty ? null : address.trim(),
      'date': date.toIso8601String(),
      'time': time.trim(),
      'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
      'organizer': organizer.trim().isEmpty ? null : organizer.trim(),
      'is_free': isFree,
      'price': isFree || price.trim().isEmpty ? null : price.trim(),
    });
  }
}

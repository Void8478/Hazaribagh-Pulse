import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/content_display.dart';
import '../../../models/category_model.dart';
import '../../../models/event_model.dart';
import '../../../models/place_model.dart';

class SupabaseAdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<Map<String, dynamic>> starterCategories = [
    {
      'name': 'Gyms',
      'slug': 'gyms',
      'icon_name': 'fitness_center',
      'description': 'Fitness centers, training clubs, and wellness gyms.',
      'manual_rank': 1,
    },
    {
      'name': 'Hospitals',
      'slug': 'hospitals',
      'icon_name': 'local_hospital',
      'description': 'Hospitals, emergency care, and medical centers.',
      'manual_rank': 2,
    },
    {
      'name': 'Doctors',
      'slug': 'doctors',
      'icon_name': 'medical',
      'description': 'Clinics, specialists, and doctor listings.',
      'manual_rank': 3,
    },
    {
      'name': 'Cafes',
      'slug': 'cafes',
      'icon_name': 'local_cafe',
      'description': 'Coffee shops, bakeries, and casual cafe spaces.',
      'manual_rank': 4,
    },
    {
      'name': 'Restaurants',
      'slug': 'restaurants',
      'icon_name': 'restaurant',
      'description': 'Dining spots, eateries, and local food favorites.',
      'manual_rank': 5,
    },
    {
      'name': 'Hotels',
      'slug': 'hotels',
      'icon_name': 'hotel',
      'description': 'Hotels, guest stays, and accommodation listings.',
      'manual_rank': 6,
    },
    {
      'name': 'Salons',
      'slug': 'salons',
      'icon_name': 'spa',
      'description': 'Beauty, grooming, and salon services.',
      'manual_rank': 7,
    },
    {
      'name': 'Tourism',
      'slug': 'tourism',
      'icon_name': 'landscape',
      'description': 'Tourist spots, parks, and local attractions.',
      'manual_rank': 8,
    },
    {
      'name': 'Shopping',
      'slug': 'shopping',
      'icon_name': 'shopping_bag',
      'description': 'Markets, stores, and shopping destinations.',
      'manual_rank': 9,
    },
    {
      'name': 'Services',
      'slug': 'services',
      'icon_name': 'handyman',
      'description': 'Repair, maintenance, and essential local services.',
      'manual_rank': 10,
    },
    {
      'name': 'Events',
      'slug': 'events',
      'icon_name': 'celebration',
      'description': 'Community events, launches, festivals, and meetups.',
      'manual_rank': 11,
    },
  ];

  Object _normalizedId(String id) => int.tryParse(id) ?? id;

  String _trimmed(String value) => value.trim();

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int _intValue(int? value) => value ?? 0;

  double _doubleValue(double? value) => value ?? 0;

  String? _locationValue({
    required String address,
    required String city,
    required String area,
    String explicit = '',
  }) {
    final location = firstNonEmpty([
      explicit,
      joinNonEmpty([area, city]),
      city,
      area,
      address,
    ]);
    return location.isEmpty ? null : location;
  }

  String get currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to manage admin content.');
    }
    return user.id;
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .order('manual_rank', ascending: true)
        .order('name', ascending: true);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(CategoryModel.fromJson).toList();
  }

  Future<void> ensureStarterCategories() async {
    final existing = await fetchCategories();
    final existingBySlug = {
      for (final category in existing)
        if (category.slug.trim().isNotEmpty) category.slug.trim().toLowerCase(): category,
    };

    for (final template in starterCategories) {
      final slug = (template['slug'] ?? '').toString().toLowerCase();
      final category = existingBySlug[slug];
      if (category == null) {
        await createCategory(
          name: template['name'].toString(),
          slug: slug,
          iconName: template['icon_name'].toString(),
          description: template['description'].toString(),
          manualRank: template['manual_rank'] as int,
          isActive: true,
        );
        continue;
      }

      await updateCategory(
        id: category.id,
        name: template['name'].toString(),
        slug: slug,
        iconName: template['icon_name'].toString(),
        description: category.description.isNotEmpty
            ? category.description
            : template['description'].toString(),
        manualRank: template['manual_rank'] as int,
        isActive: true,
      );
    }
  }

  Future<List<PlaceModel>> fetchListings({String searchQuery = ''}) async {
    dynamic query = _supabase
        .from('listings')
        .select('*, categories(id, name)')
        .order('is_featured', ascending: false)
        .order('manual_rank', ascending: true)
        .order('created_at', ascending: false);

    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isNotEmpty) {
      query = query.or(
        'name.ilike.%$trimmedQuery%,title.ilike.%$trimmedQuery%,description.ilike.%$trimmedQuery%,address.ilike.%$trimmedQuery%,city.ilike.%$trimmedQuery%,area.ilike.%$trimmedQuery%',
      );
    }

    final response = await query;
    final rows = (response as List).cast<Map<String, dynamic>>();

    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final categoryMap = row['categories'] is Map
          ? Map<String, dynamic>.from(row['categories'] as Map)
          : null;
      if (categoryMap != null && (merged['category'] == null || merged['category'] == '')) {
        merged['category'] = categoryMap['name'];
      }
      return PlaceModel.fromJson(merged);
    }).toList();
  }

  Future<List<EventModel>> fetchEvents() async {
    final response = await _supabase
        .from('events')
        .select('*, categories(id, name)')
        .order('is_featured', ascending: false)
        .order('manual_rank', ascending: true)
        .order('start_date', ascending: true);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final categoryMap = row['categories'] is Map
          ? Map<String, dynamic>.from(row['categories'] as Map)
          : null;
      if (categoryMap != null && (merged['category'] == null || merged['category'] == '')) {
        merged['category'] = categoryMap['name'];
      }
      return EventModel.fromJson(merged);
    }).toList();
  }

  Future<void> createCategory({
    required String name,
    required String slug,
    required String iconName,
    required String description,
    required int manualRank,
    required bool isActive,
  }) async {
    await _supabase.from('categories').insert({
      'name': _trimmed(name),
      'slug': _slugify(slug.isEmpty ? name : slug),
      'icon_name': _nullableText(iconName),
      'description': _nullableText(description),
      'manual_rank': manualRank,
      'display_order': manualRank,
      'is_active': isActive,
    });
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String slug,
    required String iconName,
    required String description,
    required int manualRank,
    required bool isActive,
  }) async {
    await _supabase.from('categories').update({
      'name': _trimmed(name),
      'slug': _slugify(slug.isEmpty ? name : slug),
      'icon_name': _nullableText(iconName),
      'description': _nullableText(description),
      'manual_rank': manualRank,
      'display_order': manualRank,
      'is_active': isActive,
    }).eq('id', _normalizedId(id));
  }

  Future<void> createListing({
    required String name,
    required String description,
    required String categoryId,
    required String address,
    required String city,
    required String area,
    required String imageUrl,
    required String phoneNumber,
    required String openingHours,
    required double rating,
    required int totalReviews,
    required bool isVerified,
    required bool isFeatured,
    required String status,
    required int manualRank,
  }) async {
    await _supabase.from('listings').insert({
      'user_id': currentUserId,
      'name': _trimmed(name),
      'title': _trimmed(name),
      'description': _trimmed(description),
      'category_id': _normalizedId(categoryId),
      'address': _trimmed(address),
      'city': _nullableText(city),
      'area': _nullableText(area),
      'location': _locationValue(address: address, city: city, area: area),
      'image_url': _nullableText(imageUrl),
      'phone_number': _nullableText(phoneNumber),
      'phone': _nullableText(phoneNumber),
      'opening_hours': _nullableText(openingHours),
      'rating': _doubleValue(rating),
      'total_reviews': _intValue(totalReviews),
      'review_count': _intValue(totalReviews),
      'is_verified': isVerified,
      'is_featured': isFeatured,
      'status': status,
      'manual_rank': manualRank,
    });
  }

  Future<void> updateListing({
    required String id,
    required String name,
    required String description,
    required String categoryId,
    required String address,
    required String city,
    required String area,
    required String imageUrl,
    required String phoneNumber,
    required String openingHours,
    required double rating,
    required int totalReviews,
    required bool isVerified,
    required bool isFeatured,
    required String status,
    required int manualRank,
  }) async {
    await _supabase.from('listings').update({
      'name': _trimmed(name),
      'title': _trimmed(name),
      'description': _trimmed(description),
      'category_id': _normalizedId(categoryId),
      'address': _trimmed(address),
      'city': _nullableText(city),
      'area': _nullableText(area),
      'location': _locationValue(address: address, city: city, area: area),
      'image_url': _nullableText(imageUrl),
      'phone_number': _nullableText(phoneNumber),
      'phone': _nullableText(phoneNumber),
      'opening_hours': _nullableText(openingHours),
      'rating': _doubleValue(rating),
      'total_reviews': _intValue(totalReviews),
      'review_count': _intValue(totalReviews),
      'is_verified': isVerified,
      'is_featured': isFeatured,
      'status': status,
      'manual_rank': manualRank,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _normalizedId(id));
  }

  Future<void> deleteListing(String id) async {
    await _supabase.from('listings').delete().eq('id', _normalizedId(id));
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required String categoryId,
    required String categoryName,
    required String location,
    required String address,
    required String city,
    required String area,
    required DateTime startDate,
    required DateTime? endDate,
    required String imageUrl,
    required bool isFeatured,
    required String status,
    required int manualRank,
  }) async {
    await _supabase.from('events').insert({
      'user_id': currentUserId,
      'title': _trimmed(title),
      'description': _trimmed(description),
      'category_id': categoryId.isEmpty ? null : _normalizedId(categoryId),
      'category': _nullableText(categoryName),
      'location': _locationValue(
        explicit: location,
        address: address,
        city: city,
        area: area,
      ),
      'address': _nullableText(address),
      'city': _nullableText(city),
      'area': _nullableText(area),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'date': startDate.toIso8601String(),
      'image_url': _nullableText(imageUrl),
      'is_featured': isFeatured,
      'status': status,
      'manual_rank': manualRank,
      'time': null,
      'organizer': null,
    });
  }

  Future<void> updateEvent({
    required String id,
    required String title,
    required String description,
    required String categoryId,
    required String categoryName,
    required String location,
    required String address,
    required String city,
    required String area,
    required DateTime startDate,
    required DateTime? endDate,
    required String imageUrl,
    required bool isFeatured,
    required String status,
    required int manualRank,
  }) async {
    await _supabase.from('events').update({
      'title': _trimmed(title),
      'description': _trimmed(description),
      'category_id': categoryId.isEmpty ? null : _normalizedId(categoryId),
      'category': _nullableText(categoryName),
      'location': _locationValue(
        explicit: location,
        address: address,
        city: city,
        area: area,
      ),
      'address': _nullableText(address),
      'city': _nullableText(city),
      'area': _nullableText(area),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'date': startDate.toIso8601String(),
      'image_url': _nullableText(imageUrl),
      'is_featured': isFeatured,
      'status': status,
      'manual_rank': manualRank,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _normalizedId(id));
  }

  Future<void> deleteEvent(String id) async {
    await _supabase.from('events').delete().eq('id', _normalizedId(id));
  }
}

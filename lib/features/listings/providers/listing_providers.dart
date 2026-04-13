import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/category_model.dart';
import '../../../../models/place_model.dart';
import '../../explore/providers/explore_providers.dart';
import '../services/supabase_listing_service.dart';
import '../repositories/listing_repository.dart';

final listingServiceProvider = Provider<SupabaseListingService>((ref) {
  return SupabaseListingService();
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  final service = ref.watch(listingServiceProvider);
  return ListingRepository(service);
});

final allListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchAllListings();
});

final allCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchAllCategories();
});

final listingDetailProvider = FutureProvider.family<PlaceModel, String>((ref, id) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.fetchListingById(id);
});

final categoryListingsProvider = FutureProvider.family<List<PlaceModel>, String>((ref, category) async {
  final categories = await ref.watch(allCategoriesProvider.future);
  CategoryModel? matchedCategory;
  for (final item in categories) {
    if (item.name == category) {
      matchedCategory = item;
      break;
    }
  }

  if (matchedCategory == null) {
    final allListings = await ref.watch(allListingsProvider.future);
    return allListings.where((place) => place.category == category).toList();
  }

  return ref
      .watch(listingRepositoryProvider)
      .fetchCategoryListings(matchedCategory.id);
});

final filteredListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final allListings = await ref.watch(allListingsProvider.future);
  final selectedCategory = ref.watch(exploreCategoryProvider);
  final locationQuery = ref.watch(exploreLocationProvider).trim().toLowerCase();
  final searchQuery = ref.watch(exploreSearchQueryProvider).trim().toLowerCase();

  return allListings.where((place) {
    final matchesCategory =
        selectedCategory == null || place.category == selectedCategory;
    final matchesLocation = locationQuery.isEmpty ||
        place.location.toLowerCase().contains(locationQuery) ||
        place.address.toLowerCase().contains(locationQuery);
    final matchesSearch = searchQuery.isEmpty ||
        place.name.toLowerCase().contains(searchQuery) ||
        place.description.toLowerCase().contains(searchQuery) ||
        place.category.toLowerCase().contains(searchQuery) ||
        place.location.toLowerCase().contains(searchQuery);

    return matchesCategory && matchesLocation && matchesSearch;
  }).toList();
});

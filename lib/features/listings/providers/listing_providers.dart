import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/category_model.dart';
import '../../../../models/place_model.dart';
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
  final allListings = await ref.watch(allListingsProvider.future);
  return allListings.where((place) => place.category == category).toList();
});

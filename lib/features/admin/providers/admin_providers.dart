import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../profile/providers/profile_providers.dart';
import '../services/supabase_admin_service.dart';

final adminServiceProvider = Provider<SupabaseAdminService>((ref) {
  return SupabaseAdminService();
});

final adminAccessStateProvider = Provider<AsyncValue<bool>>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.whenData((profile) => profile?.isAdmin ?? false);
});

final adminAccessProvider = Provider<bool>((ref) {
  return ref.watch(adminAccessStateProvider).maybeWhen(
        data: (value) => value,
        orElse: () => false,
      );
});

final adminCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.fetchCategories();
});

class AdminListingSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

final adminListingSearchProvider =
    NotifierProvider<AdminListingSearchNotifier, String>(
  AdminListingSearchNotifier.new,
);

final adminListingsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  final searchQuery = ref.watch(adminListingSearchProvider);
  return service.fetchListings(searchQuery: searchQuery);
});

final adminEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.fetchEvents();
});

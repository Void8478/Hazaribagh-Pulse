import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/content_display.dart';
import '../../../models/category_model.dart';
import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../events/providers/event_providers.dart';
import '../../explore/providers/explore_providers.dart';
import '../../home/providers/home_providers.dart';
import '../../listings/providers/listing_providers.dart';
import '../providers/admin_providers.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _listingSearchController = TextEditingController();

  Future<void> _ensureStarterCategories() async {
    try {
      await ref.read(adminServiceProvider).ensureStarterCategories();
      _invalidateAdminData();
      _showMessage('Starter categories are ready for your first content batch.');
    } catch (error) {
      _showMessage('Failed to prepare starter categories: $error', isError: true);
    }
  }

  @override
  void dispose() {
    _listingSearchController.dispose();
    super.dispose();
  }

  void _invalidateAdminData() {
    ref.invalidate(adminCategoriesProvider);
    ref.invalidate(adminListingsProvider);
    ref.invalidate(adminEventsProvider);
    ref.invalidate(allCategoriesProvider);
    ref.invalidate(allListingsProvider);
    ref.invalidate(filteredListingsProvider);
    ref.invalidate(listingDetailProvider);
    ref.invalidate(categoryListingsProvider);
    ref.invalidate(allEventsProvider);
    ref.invalidate(categoryEventsProvider);
    ref.invalidate(eventDetailProvider);
    ref.invalidate(homeFeaturedListingsProvider);
    ref.invalidate(homeRankedListingsProvider);
    ref.invalidate(homeCategorySectionsProvider);
    ref.invalidate(homeUpcomingEventsProvider);
    ref.invalidate(globalSearchResultsProvider);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
      ),
    );
  }

  Future<void> _openCategoryForm({CategoryModel? category}) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CategoryFormSheet(category: category),
    );

    if (didSave == true) {
      _invalidateAdminData();
      _showMessage(
        category == null
            ? 'Category saved and public category lists refreshed.'
            : 'Category updated and public category lists refreshed.',
      );
    }
  }

  Future<void> _openListingForm({
    PlaceModel? listing,
    required List<CategoryModel> categories,
  }) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ListingFormSheet(
        listing: listing,
        categories: categories,
      ),
    );

    if (didSave == true) {
      _invalidateAdminData();
      _showMessage(
        listing == null
            ? 'Listing saved and public screens refreshed.'
            : 'Listing updated and public screens refreshed.',
      );
    }
  }

  Future<void> _openEventForm({
    EventModel? event,
    required List<CategoryModel> categories,
  }) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EventFormSheet(
        event: event,
        categories: categories,
      ),
    );

    if (didSave == true) {
      _invalidateAdminData();
      _showMessage(
        event == null
            ? 'Event saved and public screens refreshed.'
            : 'Event updated and public screens refreshed.',
      );
    }
  }

  Future<bool?> _showDeleteDialog({
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteListing(PlaceModel listing) async {
    final confirmed = await _showDeleteDialog(
      title: 'Delete listing?',
      message:
          'This will permanently remove "${listing.name}" from your listings table.',
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminServiceProvider).deleteListing(listing.id);
      _invalidateAdminData();
      _showMessage('Listing deleted.');
    } catch (error) {
      _showMessage('Failed to delete listing: $error', isError: true);
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirmed = await _showDeleteDialog(
      title: 'Delete event?',
      message:
          'This will permanently remove "${event.title}" from your events table.',
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminServiceProvider).deleteEvent(event.id);
      _invalidateAdminData();
      _showMessage('Event deleted.');
    } catch (error) {
      _showMessage('Failed to delete event: $error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final adminAccessAsync = ref.watch(adminAccessStateProvider);
    final hasAdminAccess = adminAccessAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Categories'),
              Tab(text: 'Listings'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: adminAccessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminMessageState(
            icon: Icons.cloud_off_rounded,
            title: 'We could not verify admin access.',
            subtitle: '$error',
          ),
          data: (hasAccess) {
            if (!hasAccess) {
              return const _AdminMessageState(
                icon: Icons.lock_outline_rounded,
                title: 'Admin access required',
                subtitle:
                    'This screen is only available for accounts marked as admin in your profiles table.',
              );
            }

            final categoriesAsync = ref.watch(adminCategoriesProvider);
            final listingsAsync = ref.watch(adminListingsProvider);
            final eventsAsync = ref.watch(adminEventsProvider);

            return TabBarView(
              children: [
                categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _AdminMessageState(
                    icon: Icons.category_outlined,
                    title: 'Categories failed to load',
                    subtitle: '$error',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(adminCategoriesProvider),
                  ),
                  data: (categories) => _CategoryTab(
                    categories: categories,
                    onPrepareStarterSet: _ensureStarterCategories,
                    onAdd: () => _openCategoryForm(),
                    onEdit: (category) => _openCategoryForm(category: category),
                    onRefresh: () async => ref.invalidate(adminCategoriesProvider),
                  ),
                ),
                categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _AdminMessageState(
                    icon: Icons.store_mall_directory_outlined,
                    title: 'Listings failed to load',
                    subtitle: '$error',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(adminListingsProvider),
                  ),
                  data: (categories) => listingsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _AdminMessageState(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'Listings failed to load',
                      subtitle: '$error',
                      actionLabel: 'Retry',
                      onAction: () => ref.invalidate(adminListingsProvider),
                    ),
                    data: (listings) => _ListingTab(
                      listings: listings,
                      searchController: _listingSearchController,
                      onSearchChanged: (value) => ref
                          .read(adminListingSearchProvider.notifier)
                          .setQuery(value),
                      onAdd: () => _openListingForm(categories: categories),
                      onEdit: (listing) => _openListingForm(
                        listing: listing,
                        categories: categories,
                      ),
                      onDelete: _deleteListing,
                      onRefresh: () async => _invalidateAdminData(),
                    ),
                  ),
                ),
                categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _AdminMessageState(
                    icon: Icons.event_note_rounded,
                    title: 'Events failed to load',
                    subtitle: '$error',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(adminEventsProvider),
                  ),
                  data: (categories) => eventsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _AdminMessageState(
                      icon: Icons.event_note_rounded,
                      title: 'Events failed to load',
                      subtitle: '$error',
                      actionLabel: 'Retry',
                      onAction: () => ref.invalidate(adminEventsProvider),
                    ),
                    data: (events) => _EventTab(
                      events: events,
                      onAdd: () => _openEventForm(categories: categories),
                      onEdit: (event) => _openEventForm(
                        event: event,
                        categories: categories,
                      ),
                      onDelete: _deleteEvent,
                      onRefresh: () async => _invalidateAdminData(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: hasAdminAccess
            ? FloatingActionButton.extended(
                onPressed: _invalidateAdminData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Refresh',
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              )
            : null,
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.categories,
    required this.onPrepareStarterSet,
    required this.onAdd,
    required this.onEdit,
    required this.onRefresh,
  });

  final List<CategoryModel> categories;
  final VoidCallback onPrepareStarterSet;
  final VoidCallback onAdd;
  final ValueChanged<CategoryModel> onEdit;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _SectionIntroCard(
            title: 'Categories',
            subtitle: 'Manage active states, icons, and manual ordering.',
            actionLabel: 'Add Category',
            onAction: onAdd,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPrepareStarterSet,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('Prepare Starter Categories'),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const _InlineEmptyState(
              title: 'No categories yet',
              subtitle: 'Create your first category to organize listings and events.',
            )
          else
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AdminListCard(
                  title: category.name,
                  subtitle: [
                    if (category.slug.isNotEmpty) category.slug,
                    if (category.description.isNotEmpty) category.description,
                  ].join(' - '),
                  badges: [
                    _AdminBadge(
                      label: 'Rank ${category.manualRank}',
                      icon: Icons.swap_vert_rounded,
                    ),
                    _AdminBadge(
                      label: category.isActive ? 'Active' : 'Hidden',
                      icon: category.isActive
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      highlighted: category.isActive,
                    ),
                  ],
                  trailing: IconButton(
                    onPressed: () => onEdit(category),
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit category',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListingTab extends StatelessWidget {
  const _ListingTab({
    required this.listings,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<PlaceModel> listings;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;
  final ValueChanged<PlaceModel> onEdit;
  final ValueChanged<PlaceModel> onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _SectionIntroCard(
            title: 'Listings / Places',
            subtitle: 'Search, rank, feature, and update live business records.',
            actionLabel: 'Add Listing',
            onAction: onAdd,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search listings by name, address, city, or area',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (listings.isEmpty)
            const _InlineEmptyState(
              title: 'No listings found',
              subtitle: 'Create a listing or adjust your search query.',
            )
          else
            ...listings.map(
              (listing) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AdminListCard(
                  title: listing.name,
                  subtitle: [
                    if (listing.category.isNotEmpty) listing.category,
                    if (listing.address.isNotEmpty) listing.address,
                    if (listing.city.isNotEmpty || listing.area.isNotEmpty)
                      [listing.area, listing.city]
                          .where((item) => item.trim().isNotEmpty)
                          .join(', '),
                  ].join(' - '),
                  badges: [
                    if (listing.isFeatured)
                      const _AdminBadge(
                        label: 'Featured',
                        icon: Icons.star_rounded,
                        highlighted: true,
                      ),
                    _AdminBadge(
                      label: listing.status,
                      icon: Icons.flag_rounded,
                    ),
                    _AdminBadge(
                      label: 'Rank ${listing.manualRank}',
                      icon: Icons.swap_vert_rounded,
                    ),
                    if (listing.isVerified)
                      const _AdminBadge(
                        label: 'Verified',
                        icon: Icons.verified_rounded,
                      ),
                  ],
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(listing);
                      } else if (value == 'delete') {
                        onDelete(listing);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                      PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventTab extends StatelessWidget {
  const _EventTab({
    required this.events,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<EventModel> events;
  final VoidCallback onAdd;
  final ValueChanged<EventModel> onEdit;
  final ValueChanged<EventModel> onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _SectionIntroCard(
            title: 'Events',
            subtitle: 'Manage what is upcoming, featured, or hidden from the app.',
            actionLabel: 'Add Event',
            onAction: onAdd,
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            const _InlineEmptyState(
              title: 'No events yet',
              subtitle: 'Create an event to populate Home and Explore.',
            )
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AdminListCard(
                  title: event.title,
                  subtitle: [
                    if (event.categoryLabel.isNotEmpty) event.categoryLabel,
                    if (event.locationLabel.isNotEmpty) event.locationLabel,
                    formatShortDate(event.startDateOrNull),
                  ].join(' - '),
                  badges: [
                    if (event.isFeatured)
                      const _AdminBadge(
                        label: 'Featured',
                        icon: Icons.star_rounded,
                        highlighted: true,
                      ),
                    _AdminBadge(label: event.status, icon: Icons.flag_rounded),
                    _AdminBadge(
                      label: 'Rank ${event.manualRank}',
                      icon: Icons.swap_vert_rounded,
                    ),
                  ],
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(event);
                      } else if (value == 'delete') {
                        onDelete(event);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                      PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({this.category});

  final CategoryModel? category;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _iconController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _manualRankController;
  late bool _isActive;
  bool _isSaving = false;
  bool _hasEditedSlug = false;

  static const List<String> _iconSuggestions = [
    'fitness_center',
    'local_hospital',
    'medical',
    'local_cafe',
    'restaurant',
    'hotel',
    'spa',
    'landscape',
    'shopping_bag',
    'handyman',
    'celebration',
  ];

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _slugController = TextEditingController(text: category?.slug ?? '');
    _iconController = TextEditingController(text: category?.iconName ?? '');
    _descriptionController = TextEditingController(text: category?.description ?? '');
    _manualRankController = TextEditingController(
      text: (category?.manualRank ?? 0).toString(),
    );
    _isActive = category?.isActive ?? true;
    _hasEditedSlug = (category?.slug ?? '').trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _manualRankController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(adminServiceProvider);
      final manualRank = int.tryParse(_manualRankController.text.trim()) ?? 0;

      if (widget.category == null) {
        await service.createCategory(
          name: _nameController.text,
          slug: _slugController.text,
          iconName: _iconController.text,
          description: _descriptionController.text,
          manualRank: manualRank,
          isActive: _isActive,
        );
      } else {
        await service.updateCategory(
          id: widget.category!.id,
          name: _nameController.text,
          slug: _slugController.text,
          iconName: _iconController.text,
          description: _descriptionController.text,
          manualRank: manualRank,
          isActive: _isActive,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save category: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormContainer(
      title: widget.category == null ? 'Add Category' : 'Edit Category',
      isSaving: _isSaving,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FormSectionLabel('Category details'),
            _AdminTextField(
              controller: _nameController,
              label: 'Name',
              hintText: 'Gyms, Hospitals, Doctors, Cafes...',
              onChanged: (value) {
                if (_hasEditedSlug && widget.category != null) {
                  return;
                }
                if (!_hasEditedSlug) {
                  _slugController.text = _slugify(value);
                }
              },
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _slugController,
              label: 'Slug',
              hintText: 'gyms',
              onChanged: (_) => _hasEditedSlug = true,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _iconSuggestions.contains(_iconController.text)
                  ? _iconController.text
                  : null,
              decoration: const InputDecoration(labelText: 'Icon name'),
              items: _iconSuggestions
                  .map(
                    (icon) => DropdownMenuItem<String>(
                      value: icon,
                      child: Text(icon),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _iconController.text = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _iconController,
              label: 'Custom icon override',
              hintText: 'Optional custom Material icon name',
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _manualRankController,
              label: 'Manual rank',
              keyboardType: TextInputType.number,
              validator: _nonNegativeNumberValidator,
              helperText: 'Lower numbers appear first in public category lists.',
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active category'),
              subtitle: const Text('Turn this off to hide the category in the app.'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingFormSheet extends ConsumerStatefulWidget {
  const _ListingFormSheet({
    this.listing,
    required this.categories,
  });

  final PlaceModel? listing;
  final List<CategoryModel> categories;

  @override
  ConsumerState<_ListingFormSheet> createState() => _ListingFormSheetState();
}

class _ListingFormSheetState extends ConsumerState<_ListingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _phoneController;
  late final TextEditingController _openingHoursController;
  late final TextEditingController _ratingController;
  late final TextEditingController _totalReviewsController;
  late final TextEditingController _manualRankController;
  late String _selectedCategoryId;
  late String _selectedStatus;
  late bool _isVerified;
  late bool _isFeatured;
  bool _isSaving = false;

  static const List<String> _statusOptions = [
    'active',
    'draft',
    'hidden',
    'inactive',
  ];

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    _nameController = TextEditingController(text: listing?.name ?? '');
    _descriptionController = TextEditingController(text: listing?.description ?? '');
    _addressController = TextEditingController(text: listing?.address ?? '');
    _cityController = TextEditingController(text: listing?.city ?? 'Hazaribagh');
    _areaController = TextEditingController(text: listing?.area ?? '');
    _imageUrlController = TextEditingController(text: listing?.imageUrl ?? '');
    _phoneController = TextEditingController(text: listing?.phone ?? '');
    _openingHoursController = TextEditingController(
      text: listing?.openingHours ?? '',
    );
    _ratingController = TextEditingController(
      text: (listing?.rating ?? 0).toString(),
    );
    _totalReviewsController = TextEditingController(
      text: (listing?.reviewCount ?? 0).toString(),
    );
    _manualRankController = TextEditingController(
      text: (listing?.manualRank ?? 0).toString(),
    );
    _selectedCategoryId = listing?.categoryId ?? '';
    _selectedStatus =
        _statusOptions.contains(listing?.status) ? listing!.status : 'active';
    _isVerified = listing?.isVerified ?? false;
    _isFeatured = listing?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _imageUrlController.dispose();
    _phoneController.dispose();
    _openingHoursController.dispose();
    _ratingController.dispose();
    _totalReviewsController.dispose();
    _manualRankController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(adminServiceProvider);
      final rating = double.tryParse(_ratingController.text.trim()) ?? 0;
      final totalReviews = int.tryParse(_totalReviewsController.text.trim()) ?? 0;
      final manualRank = int.tryParse(_manualRankController.text.trim()) ?? 0;

      if (widget.listing == null) {
        await service.createListing(
          name: _nameController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategoryId,
          address: _addressController.text,
          city: _cityController.text,
          area: _areaController.text,
          imageUrl: _imageUrlController.text,
          phoneNumber: _phoneController.text,
          openingHours: _openingHoursController.text,
          rating: rating,
          totalReviews: totalReviews,
          isVerified: _isVerified,
          isFeatured: _isFeatured,
          status: _selectedStatus,
          manualRank: manualRank,
        );
      } else {
        await service.updateListing(
          id: widget.listing!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategoryId,
          address: _addressController.text,
          city: _cityController.text,
          area: _areaController.text,
          imageUrl: _imageUrlController.text,
          phoneNumber: _phoneController.text,
          openingHours: _openingHoursController.text,
          rating: rating,
          totalReviews: totalReviews,
          isVerified: _isVerified,
          isFeatured: _isFeatured,
          status: _selectedStatus,
          manualRank: manualRank,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save listing: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormContainer(
      title: widget.listing == null ? 'Add Listing' : 'Edit Listing',
      isSaving: _isSaving,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FormSectionLabel('Basics'),
            _AdminTextField(
              controller: _nameController,
              label: 'Listing name',
              hintText: 'Pulse Fitness Club',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value ?? ''),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Category is required' : null,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              hintText: 'What makes this place useful for real users?',
              validator: _requiredValidator,
              helperText: 'Keep it clear and factual so it reads well in Home, Explore, and Search.',
            ),
            const SizedBox(height: 12),
            const _FormSectionLabel('Location'),
            _AdminTextField(
              controller: _addressController,
              label: 'Address',
              hintText: 'Main Road, Hazaribagh',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminTextField(
                    controller: _cityController,
                    label: 'City',
                    hintText: 'Hazaribagh',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminTextField(
                    controller: _areaController,
                    label: 'Area',
                    hintText: 'Matwari, Canary Hill...',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FormSectionLabel('Contact and media'),
            _AdminTextField(
              controller: _imageUrlController,
              label: 'Image URL',
              hintText: 'https://...',
              helperText: 'Optional. Leave empty to use the in-app image fallback.',
              validator: _optionalImageUrlValidator,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _ImagePreviewCard(
              url: _imageUrlController.text,
              emptyLabel: 'No image URL yet. The public app will show a polished fallback state.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    hintText: '+91...',
                    keyboardType: TextInputType.phone,
                    validator: _optionalPhoneValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminTextField(
                    controller: _openingHoursController,
                    label: 'Opening hours',
                    hintText: '6:00 AM - 10:00 PM',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FormSectionLabel('Quality signals'),
            Row(
              children: [
                Expanded(
                  child: _AdminTextField(
                    controller: _ratingController,
                    label: 'Rating',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: '4.5',
                    validator: _ratingValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminTextField(
                    controller: _totalReviewsController,
                    label: 'Total reviews',
                    keyboardType: TextInputType.number,
                    hintText: '24',
                    validator: _nonNegativeNumberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FormSectionLabel('Publishing'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statusOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value ?? 'active'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminTextField(
                    controller: _manualRankController,
                    label: 'Manual rank',
                    keyboardType: TextInputType.number,
                    validator: _nonNegativeNumberValidator,
                    helperText: 'Lower numbers appear first.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Featured listing'),
              value: _isFeatured,
              onChanged: (value) => setState(() => _isFeatured = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Verified listing'),
              value: _isVerified,
              onChanged: (value) => setState(() => _isVerified = value),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventFormSheet extends ConsumerStatefulWidget {
  const _EventFormSheet({
    this.event,
    required this.categories,
  });

  final EventModel? event;
  final List<CategoryModel> categories;

  @override
  ConsumerState<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<_EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _manualRankController;
  late String _selectedCategoryId;
  late String _selectedStatus;
  late bool _isFeatured;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  static const List<String> _statusOptions = [
    'active',
    'draft',
    'hidden',
    'inactive',
  ];

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _addressController = TextEditingController(text: event?.address ?? '');
    _cityController = TextEditingController(text: event?.city ?? 'Hazaribagh');
    _areaController = TextEditingController(text: event?.area ?? '');
    _imageUrlController = TextEditingController(text: event?.imageUrl ?? '');
    _manualRankController = TextEditingController(
      text: (event?.manualRank ?? 0).toString(),
    );
    _selectedCategoryId = event?.categoryId ?? '';
    _selectedStatus =
        _statusOptions.contains(event?.status) ? event!.status : 'active';
    _isFeatured = event?.isFeatured ?? false;
    _startDate = event?.startDate ?? DateTime.now();
    _endDate = event?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _imageUrlController.dispose();
    _manualRankController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final initialDate = _endDate ?? _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final selectedCategory = widget.categories.where(
        (category) => category.id == _selectedCategoryId,
      );
      final categoryName = selectedCategory.isEmpty ? '' : selectedCategory.first.name;
      final service = ref.read(adminServiceProvider);
      final manualRank = int.tryParse(_manualRankController.text.trim()) ?? 0;

      if (widget.event == null) {
        await service.createEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategoryId,
          categoryName: categoryName,
          location: _locationController.text,
          address: _addressController.text,
          city: _cityController.text,
          area: _areaController.text,
          startDate: _startDate,
          endDate: _endDate,
          imageUrl: _imageUrlController.text,
          isFeatured: _isFeatured,
          status: _selectedStatus,
          manualRank: manualRank,
        );
      } else {
        await service.updateEvent(
          id: widget.event!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategoryId,
          categoryName: categoryName,
          location: _locationController.text,
          address: _addressController.text,
          city: _cityController.text,
          area: _areaController.text,
          startDate: _startDate,
          endDate: _endDate,
          imageUrl: _imageUrlController.text,
          isFeatured: _isFeatured,
          status: _selectedStatus,
          manualRank: manualRank,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save event: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormContainer(
      title: widget.event == null ? 'Add Event' : 'Edit Event',
      isSaving: _isSaving,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FormSectionLabel('Basics'),
            _AdminTextField(
              controller: _titleController,
              label: 'Title',
              hintText: 'Weekend Flea Market',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value ?? ''),
              hint: const Text('Optional'),
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              hintText: 'What should users know before attending?',
              validator: _requiredValidator,
              helperText: 'Use a clean public-facing summary for event cards and detail pages.',
            ),
            const SizedBox(height: 12),
            const _FormSectionLabel('Venue'),
            _AdminTextField(
              controller: _locationController,
              label: 'Location',
              hintText: 'Town Hall',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _addressController,
              label: 'Address',
              hintText: 'Near Lake Road',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminTextField(
                    controller: _cityController,
                    label: 'City',
                    hintText: 'Hazaribagh',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminTextField(
                    controller: _areaController,
                    label: 'Area',
                    hintText: 'Canary Hill',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _imageUrlController,
              label: 'Image URL',
              hintText: 'https://...',
              helperText: 'Optional. Leave empty to use the event image fallback.',
              validator: _optionalImageUrlValidator,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _ImagePreviewCard(
              url: _imageUrlController.text,
              emptyLabel: 'No image URL yet. The public app will show a clean event fallback.',
            ),
            const SizedBox(height: 12),
            const _FormSectionLabel('Schedule and publishing'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.event_rounded),
                    label: Text('Start ${_formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.event_available_rounded),
                    label: Text(
                      _endDate == null ? 'End date' : 'End ${_formatDate(_endDate!)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statusOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value ?? 'active'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminTextField(
                    controller: _manualRankController,
                    label: 'Manual rank',
                    keyboardType: TextInputType.number,
                    validator: _nonNegativeNumberValidator,
                    helperText: 'Lower numbers appear first.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Featured event'),
              value: _isFeatured,
              onChanged: (value) => setState(() => _isFeatured = value),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminFormContainer extends StatelessWidget {
  const _AdminFormContainer({
    required this.title,
    required this.isSaving,
    required this.onSave,
    required this.child,
  });

  final String title;
  final bool isSaving;
  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(isSaving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionIntroCard extends StatelessWidget {
  const _SectionIntroCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _AdminListCard extends StatelessWidget {
  const _AdminListCard({
    required this.title,
    required this.subtitle,
    required this.badges,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<_AdminBadge> badges;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: badges),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({
    required this.label,
    required this.icon,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = highlighted
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = highlighted
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMessageState extends StatelessWidget {
  const _AdminMessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.onChanged,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.url,
    required this.emptyLabel,
  });

  final String url;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmedUrl = url.trim();

    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: !isValidWebImageUrl(trimmedUrl)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  trimmedUrl.isEmpty
                      ? emptyLabel
                      : 'Enter a full http or https image URL to preview it safely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : Image.network(
              trimmedUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'This image URL could not be loaded. Please verify the link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}

String? _numberValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter a number.';
  }
  if (int.tryParse(value.trim()) == null) {
    return 'Enter a valid whole number.';
  }
  return null;
}

String? _nonNegativeNumberValidator(String? value) {
  final base = _numberValidator(value);
  if (base != null) {
    return base;
  }

  if (int.parse(value!.trim()) < 0) {
    return 'Enter 0 or a positive number.';
  }

  return null;
}

String? _decimalValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter a number.';
  }
  if (double.tryParse(value.trim()) == null) {
    return 'Enter a valid number.';
  }
  return null;
}

String? _optionalImageUrlValidator(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (!isValidWebImageUrl(trimmed)) {
    return 'Use a full http or https image URL.';
  }
  return null;
}

String? _optionalPhoneValidator(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 10) {
    return 'Enter a valid phone number or leave it blank.';
  }
  return null;
}

String? _ratingValidator(String? value) {
  final base = _decimalValidator(value);
  if (base != null) {
    return base;
  }

  final parsed = double.parse(value!.trim());
  if (parsed < 0 || parsed > 5) {
    return 'Rating must be between 0 and 5.';
  }

  return null;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/create_bottom_sheet.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../listings/providers/listing_providers.dart';
import '../models/explore_search_bundle.dart';
import '../providers/explore_providers.dart';
import '../widgets/category_card.dart';
import '../widgets/explore_search_bar.dart';
import '../widgets/filter_sort_sheet.dart';
import '../widgets/global_search_result_tile.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(exploreSearchQueryProvider);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterSortSheet(),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      ref.read(exploreSearchQueryProvider.notifier).set(query);
    });
  }

  void _resetAllFilters() {
    ref.read(exploreSearchQueryProvider.notifier).set('');
    ref.read(exploreCategoryProvider.notifier).set(null);
    ref.read(exploreLocationProvider.notifier).set('');
    ref
        .read(exploreContentTypeProvider.notifier)
        .set(ExploreContentType.all);
    ref.read(exploreSortProvider.notifier).set(ExploreSortMode.mostRelevant);
    ref.read(exploreVerifiedOnlyProvider.notifier).set(false);
    ref.read(exploreSponsoredOnlyProvider.notifier).set(false);
    ref.read(exploreEventTimingProvider.notifier).set(ExploreEventTiming.all);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCategory = ref.watch(exploreCategoryProvider);
    final selectedType = ref.watch(exploreContentTypeProvider);
    final sortMode = ref.watch(exploreSortProvider);
    final location = ref.watch(exploreLocationProvider);
    final verifiedOnly = ref.watch(exploreVerifiedOnlyProvider);
    final sponsoredOnly = ref.watch(exploreSponsoredOnlyProvider);
    final eventTiming = ref.watch(exploreEventTimingProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final searchResultsAsync = ref.watch(globalSearchResultsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => showCreateSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find the best places, posts, and events in one fast search.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ExploreSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onFilterTap: _showFilterSheet,
                  ),
                  const SizedBox(height: 18),
                  _TypeTabs(
                    selectedType: selectedType,
                    onSelected: (type) {
                      ref.read(exploreContentTypeProvider.notifier).set(type);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            categoriesAsync.when(
              loading: () => const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Could not load categories',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(allCategoriesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (categories) => SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: 'All',
                        icon: Icons.grid_view_rounded,
                        isSelected: selectedCategory == null,
                        onTap: () {
                          ref.read(exploreCategoryProvider.notifier).set(null);
                        },
                      ),
                    ),
                    ...categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: category.name,
                          icon: category.icon,
                          isSelected: selectedCategory == category.name,
                          onTap: () {
                            final current = ref.read(exploreCategoryProvider);
                            ref.read(exploreCategoryProvider.notifier).set(
                                  current == category.name ? null : category.name,
                                );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: searchResultsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: PremiumEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Search unavailable',
                    subtitle: '$err',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(globalSearchResultsProvider),
                  ),
                ),
                data: (results) {
                  final selectedCount = _countForType(results, selectedType);

                  if (selectedCount == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: PremiumEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No results found',
                        subtitle:
                            'Try a different query, category, content type, or filter combination.',
                        actionLabel: 'Clear Filters',
                        onAction: _resetAllFilters,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(globalSearchResultsProvider);
                    },
                    child: ListView(
                      cacheExtent: 720,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        _ResultsToolbar(
                          totalCount: selectedCount,
                          sortLabel: _sortLabel(sortMode),
                          location: location,
                          selectedCategory: selectedCategory,
                          verifiedOnly: verifiedOnly,
                          sponsoredOnly: sponsoredOnly,
                          eventTiming: eventTiming,
                          selectedType: selectedType,
                          onFilterTap: _showFilterSheet,
                          onClear: _resetAllFilters,
                        ),
                        ..._buildSections(context, results, selectedType),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    ExploreSearchBundle results,
    ExploreContentType selectedType,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final widgets = <Widget>[];

    if (selectedType == ExploreContentType.all ||
        selectedType == ExploreContentType.places) {
      if (results.places.isNotEmpty) {
        widgets.add(
          _ResultsSection(
            title: 'Places',
            children: results.places.map((place) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlobalSearchResultTile(
                  title: place.name,
                  subtitle: place.description,
                  meta: place.category,
                  route: '/listing/${place.id}',
                  icon: Icons.storefront_rounded,
                  accentColor: colorScheme.primary,
                  imageUrl: place.imageUrl,
                  badges: [
                    if (place.isVerified) 'Verified',
                    if (place.isSponsored) 'Sponsored',
                  ],
                  trailing: Text(
                    '${place.rating.toStringAsFixed(1)} - ${results.likeCountFor('place', place.id)} likes',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }
    }

    if (selectedType == ExploreContentType.all ||
        selectedType == ExploreContentType.posts) {
      if (results.posts.isNotEmpty) {
        widgets.add(
          _ResultsSection(
            title: 'Posts',
            children: results.posts.map((post) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlobalSearchResultTile(
                  title: post.title,
                  subtitle: post.description,
                  meta: post.categoryName.isNotEmpty ? post.categoryName : 'Post',
                  route: '/post/${post.id}',
                  icon: Icons.article_rounded,
                  accentColor: colorScheme.secondary,
                  imageUrl: post.imageUrl,
                  trailing: Text(
                    '${post.location.isNotEmpty ? post.location : 'Community'} - ${results.likeCountFor('post', post.id)} likes',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }
    }

    if (selectedType == ExploreContentType.all ||
        selectedType == ExploreContentType.events) {
      if (results.events.isNotEmpty) {
        widgets.add(
          _ResultsSection(
            title: 'Events',
            children: results.events.map((event) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlobalSearchResultTile(
                  title: event.title,
                  subtitle: event.description,
                  meta: event.category.isNotEmpty ? event.category : 'Event',
                  route: '/event/${event.id}',
                  icon: Icons.event_rounded,
                  accentColor: Colors.orange,
                  imageUrl: event.imageUrl,
                  badges: [
                    if (event.date.isAfter(DateTime.now())) 'Upcoming',
                    if (event.isFree) 'Free',
                  ],
                  trailing: Text(
                    '${event.location} - ${results.likeCountFor('event', event.id)} likes',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }
    }

    return widgets;
  }

  String _sortLabel(ExploreSortMode mode) {
    switch (mode) {
      case ExploreSortMode.mostRelevant:
        return 'Relevant';
      case ExploreSortMode.newestFirst:
        return 'Newest';
      case ExploreSortMode.oldestFirst:
        return 'Oldest';
      case ExploreSortMode.mostPopular:
        return 'Popular';
      case ExploreSortMode.highestRated:
        return 'Top Rated';
    }
  }

  int _countForType(
    ExploreSearchBundle results,
    ExploreContentType selectedType,
  ) {
    switch (selectedType) {
      case ExploreContentType.all:
        return results.totalCount;
      case ExploreContentType.places:
        return results.places.length;
      case ExploreContentType.posts:
        return results.posts.length;
      case ExploreContentType.events:
        return results.events.length;
    }
  }
}

class _TypeTabs extends StatelessWidget {
  const _TypeTabs({
    required this.selectedType,
    required this.onSelected,
  });

  final ExploreContentType selectedType;
  final ValueChanged<ExploreContentType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TypeTab(
            label: 'All',
            selected: selectedType == ExploreContentType.all,
            onTap: () => onSelected(ExploreContentType.all),
          ),
          const SizedBox(width: 8),
          _TypeTab(
            label: 'Places',
            selected: selectedType == ExploreContentType.places,
            onTap: () => onSelected(ExploreContentType.places),
          ),
          const SizedBox(width: 8),
          _TypeTab(
            label: 'Posts',
            selected: selectedType == ExploreContentType.posts,
            onTap: () => onSelected(ExploreContentType.posts),
          ),
          const SizedBox(width: 8),
          _TypeTab(
            label: 'Events',
            selected: selectedType == ExploreContentType.events,
            onTap: () => onSelected(ExploreContentType.events),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ResultsToolbar extends StatelessWidget {
  const _ResultsToolbar({
    required this.totalCount,
    required this.sortLabel,
    required this.location,
    required this.selectedCategory,
    required this.verifiedOnly,
    required this.sponsoredOnly,
    required this.eventTiming,
    required this.selectedType,
    required this.onFilterTap,
    required this.onClear,
  });

  final int totalCount;
  final String sortLabel;
  final String location;
  final String? selectedCategory;
  final bool verifiedOnly;
  final bool sponsoredOnly;
  final ExploreEventTiming eventTiming;
  final ExploreContentType selectedType;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeChips = <String>[
      sortLabel,
      ?selectedCategory,
      if (location.isNotEmpty) 'Location: $location',
      if (verifiedOnly) 'Verified only',
      if (sponsoredOnly) 'Sponsored only',
      if (eventTiming == ExploreEventTiming.upcomingOnly) 'Upcoming only',
      if (eventTiming == ExploreEventTiming.pastOnly) 'Past events',
      ?(selectedType != ExploreContentType.all
          ? selectedType.name[0].toUpperCase() + selectedType.name.substring(1)
          : null),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalCount results',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Clear'),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onFilterTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeChips.map((chip) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

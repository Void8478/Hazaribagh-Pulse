import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../providers/explore_providers.dart';
import '../widgets/explore_search_bar.dart';
import '../widgets/category_card.dart';
import '../widgets/explore_listing_card.dart';
import '../widgets/filter_sort_sheet.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCategory = ref.watch(exploreCategoryProvider);
    final filteredListingsAsync = ref.watch(filteredListingsProvider);
    final sortMode = ref.watch(exploreSortProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
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
                    const SizedBox(height: 4),
                    Text(
                      'Discover the heart of Hazaribagh',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Search Bar
                    ExploreSearchBar(
                      controller: _searchController,
                      onChanged: (query) {
                        ref.read(exploreSearchQueryProvider.notifier).set(query);
                      },
                      onFilterTap: _showFilterSheet,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Category Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48, // slightly taller for new chips
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // "All" chip
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
                    ...MockData.categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: cat['name'],
                          icon: cat['icon'],
                          isSelected: selectedCategory == cat['name'],
                          onTap: () {
                            final current = ref.read(exploreCategoryProvider);
                            ref.read(exploreCategoryProvider.notifier).set(
                                current == cat['name'] ? null : cat['name']);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Trending Tags
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trending Searches',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: trendingTags.map((tag) {
                        return GestureDetector(
                          onTap: () {
                            // Extract search term (remove emoji prefix)
                            final searchTerm = tag.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                            _searchController.text = searchTerm;
                            ref.read(exploreSearchQueryProvider.notifier).set(searchTerm);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Sort indicator + Results header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    filteredListingsAsync.when(
                      data: (listings) => Text(
                        '${listings.length} places found',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort_rounded, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              _sortLabel(sortMode),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Listing Results
            filteredListingsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Failed to load listings', style: TextStyle(color: colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => ref.invalidate(filteredListingsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (listings) {
                if (listings.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: PremiumEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No places found',
                        subtitle: 'Try adjusting your search or filters',
                        actionLabel: 'Reset Filters',
                        onAction: () {
                          ref.read(exploreSearchQueryProvider.notifier).set('');
                          ref.read(exploreCategoryProvider.notifier).set(null);
                          _searchController.clear();
                        },
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AnimatedListItem(
                          delay: index * 60,
                          child: ExploreListingCard(
                            place: listings[index],
                          ),
                        );
                      },
                      childCount: listings.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(ExploreSortMode mode) {
    switch (mode) {
      case ExploreSortMode.rating:
        return 'Rating';
      case ExploreSortMode.reviews:
        return 'Reviews';
      case ExploreSortMode.nameAZ:
        return 'A-Z';
    }
  }
}

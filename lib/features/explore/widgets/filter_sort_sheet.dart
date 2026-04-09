import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/explore_providers.dart';

class FilterSortSheet extends ConsumerStatefulWidget {
  const FilterSortSheet({super.key});

  @override
  ConsumerState<FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends ConsumerState<FilterSortSheet> {
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(
      text: ref.read(exploreLocationProvider),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentSort = ref.watch(exploreSortProvider);
    final contentType = ref.watch(exploreContentTypeProvider);
    final verifiedOnly = ref.watch(exploreVerifiedOnlyProvider);
    final sponsoredOnly = ref.watch(exploreSponsoredOnlyProvider);
    final eventTiming = ref.watch(exploreEventTimingProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Search Filters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _locationController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Search in a neighborhood or area',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (value) {
                ref.read(exploreLocationProvider.notifier).set(value);
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Content Type'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildChip(
                  context,
                  label: 'All',
                  selected: contentType == ExploreContentType.all,
                  onTap: () => ref
                      .read(exploreContentTypeProvider.notifier)
                      .set(ExploreContentType.all),
                ),
                _buildChip(
                  context,
                  label: 'Places',
                  selected: contentType == ExploreContentType.places,
                  onTap: () => ref
                      .read(exploreContentTypeProvider.notifier)
                      .set(ExploreContentType.places),
                ),
                _buildChip(
                  context,
                  label: 'Posts',
                  selected: contentType == ExploreContentType.posts,
                  onTap: () => ref
                      .read(exploreContentTypeProvider.notifier)
                      .set(ExploreContentType.posts),
                ),
                _buildChip(
                  context,
                  label: 'Events',
                  selected: contentType == ExploreContentType.events,
                  onTap: () => ref
                      .read(exploreContentTypeProvider.notifier)
                      .set(ExploreContentType.events),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Sort By'),
            const SizedBox(height: 14),
            _buildSortOption(
              context,
              icon: Icons.auto_awesome_rounded,
              label: 'Most Relevant',
              mode: ExploreSortMode.mostRelevant,
              current: currentSort,
            ),
            const SizedBox(height: 8),
            _buildSortOption(
              context,
              icon: Icons.schedule_rounded,
              label: 'Newest First',
              mode: ExploreSortMode.newestFirst,
              current: currentSort,
            ),
            const SizedBox(height: 8),
            _buildSortOption(
              context,
              icon: Icons.history_rounded,
              label: 'Oldest First',
              mode: ExploreSortMode.oldestFirst,
              current: currentSort,
            ),
            const SizedBox(height: 8),
            _buildSortOption(
              context,
              icon: Icons.local_fire_department_rounded,
              label: 'Most Popular',
              mode: ExploreSortMode.mostPopular,
              current: currentSort,
            ),
            const SizedBox(height: 8),
            _buildSortOption(
              context,
              icon: Icons.star_rounded,
              label: 'Highest Rated',
              mode: ExploreSortMode.highestRated,
              current: currentSort,
            ),
            if (contentType == ExploreContentType.all ||
                contentType == ExploreContentType.places) ...[
              const SizedBox(height: 24),
              _SectionTitle(title: 'Places'),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Verified only'),
                subtitle: const Text('Show trusted places with verified status'),
                value: verifiedOnly,
                onChanged: (value) {
                  ref.read(exploreVerifiedOnlyProvider.notifier).set(value);
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sponsored only'),
                subtitle: const Text('Only show promoted listings'),
                value: sponsoredOnly,
                onChanged: (value) {
                  ref.read(exploreSponsoredOnlyProvider.notifier).set(value);
                },
              ),
            ],
            if (contentType == ExploreContentType.all ||
                contentType == ExploreContentType.events) ...[
              const SizedBox(height: 16),
              _SectionTitle(title: 'Events'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildChip(
                    context,
                    label: 'All Events',
                    selected: eventTiming == ExploreEventTiming.all,
                    onTap: () => ref
                        .read(exploreEventTimingProvider.notifier)
                        .set(ExploreEventTiming.all),
                  ),
                  _buildChip(
                    context,
                    label: 'Upcoming Only',
                    selected:
                        eventTiming == ExploreEventTiming.upcomingOnly,
                    onTap: () => ref
                        .read(exploreEventTimingProvider.notifier)
                        .set(ExploreEventTiming.upcomingOnly),
                  ),
                  _buildChip(
                    context,
                    label: 'Past Events',
                    selected: eventTiming == ExploreEventTiming.pastOnly,
                    onTap: () => ref
                        .read(exploreEventTimingProvider.notifier)
                        .set(ExploreEventTiming.pastOnly),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(exploreSortProvider.notifier)
                          .set(ExploreSortMode.mostRelevant);
                      ref.read(exploreCategoryProvider.notifier).set(null);
                      ref.read(exploreLocationProvider.notifier).set('');
                      ref
                          .read(exploreContentTypeProvider.notifier)
                          .set(ExploreContentType.all);
                      ref
                          .read(exploreVerifiedOnlyProvider.notifier)
                          .set(false);
                      ref
                          .read(exploreSponsoredOnlyProvider.notifier)
                          .set(false);
                      ref
                          .read(exploreEventTimingProvider.notifier)
                          .set(ExploreEventTiming.all);
                      _locationController.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Show Results'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.28)
                : colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ExploreSortMode mode,
    required ExploreSortMode current,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = mode == current;

    return InkWell(
      onTap: () => ref.read(exploreSortProvider.notifier).set(mode),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 22,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

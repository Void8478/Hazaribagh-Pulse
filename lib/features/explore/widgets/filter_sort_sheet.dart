import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/explore_providers.dart';

class FilterSortSheet extends ConsumerWidget {
  const FilterSortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentSort = ref.watch(exploreSortProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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
          const SizedBox(height: 20),
          
          Text(
            'Sort By',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          _buildSortOption(
            context, ref,
            icon: Icons.star_rounded,
            label: 'Highest Rating',
            mode: ExploreSortMode.rating,
            current: currentSort,
          ),
          const SizedBox(height: 8),
          _buildSortOption(
            context, ref,
            icon: Icons.trending_up_rounded,
            label: 'Most Reviews',
            mode: ExploreSortMode.reviews,
            current: currentSort,
          ),
          const SizedBox(height: 8),
          _buildSortOption(
            context, ref,
            icon: Icons.sort_by_alpha_rounded,
            label: 'Name (A-Z)',
            mode: ExploreSortMode.nameAZ,
            current: currentSort,
          ),
          const SizedBox(height: 24),

          // Reset filters
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(exploreSortProvider.notifier).set(ExploreSortMode.rating);
                ref.read(exploreCategoryProvider.notifier).set(null);
                ref.read(exploreSearchQueryProvider.notifier).set('');
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Reset All Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required ExploreSortMode mode,
    required ExploreSortMode current,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = mode == current;

    return InkWell(
      onTap: () {
        ref.read(exploreSortProvider.notifier).set(mode);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 20, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

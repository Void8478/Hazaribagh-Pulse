import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/place_card.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../listings/providers/listing_providers.dart';

class CategoryResultsScreen extends ConsumerWidget {
  final String categoryName;

  const CategoryResultsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final listingsAsync = ref.watch(categoryListingsProvider(categoryName));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: listingsAsync.when(
        loading: () => _buildLoadingSkeleton(context),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading listings',
                style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.refresh(categoryListingsProvider(categoryName)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (places) {
          if (places.isEmpty) {
            return Center(
              child: PremiumEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No listings found',
                subtitle: 'No listings available for $categoryName yet.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(categoryListingsProvider(categoryName));
              ref.invalidate(allListingsProvider);
              ref.invalidate(allCategoriesProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom: 32.0,
              ),
              itemCount: places.length,
              itemBuilder: (context, index) {
                return AnimatedListItem(
                  delay: index * 80,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PlaceCard(place: places[index], width: double.infinity),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}

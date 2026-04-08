import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/full_review_card.dart';
import '../providers/review_providers.dart';

class ReviewsListScreen extends ConsumerWidget {
  final String listingId;

  const ReviewsListScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsyncValue = ref.watch(listingReviewsProvider(listingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter dialog would open here.')),
              );
            },
          ),
        ],
      ),
      body: reviewsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error fetching reviews: $err'),
              TextButton(
                onPressed: () => ref.refresh(listingReviewsProvider(listingId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 52,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No reviews yet. Be the first to share your experience.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0, bottom: 32.0),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return FullReviewCard(review: reviews[index]);
            },
          );
        },
      ),
    );
  }
}

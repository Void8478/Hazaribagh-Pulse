import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/widgets/review_preview_card.dart';
import '../providers/profile_providers.dart';
import '../../../core/widgets/premium_empty_state.dart';

class UserReviewsSection extends ConsumerWidget {
  final String userId;

  const UserReviewsSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewsAsync = ref.watch(userReviewsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Contributions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full reviews list when route exists
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return const PremiumEmptyState(
                icon: Icons.rate_review_outlined,
                title: 'No contributions yet',
                subtitle: 'Write your first review and help the community!',
              );
            }
            
            return Column(
              children: reviews.take(3).map((review) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ReviewPreviewCard(review: review),
              )).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: PremiumEmptyState(
              icon: Icons.error_outline,
              title: 'Could not load contributions',
              subtitle: 'Pull down to retry',
            ),
          ),
        ),
      ],
    );
  }
}

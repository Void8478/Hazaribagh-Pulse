import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/rating_summary_widget.dart';
import '../widgets/action_button_row.dart';
import '../widgets/review_preview_card.dart';
import '../widgets/info_chip.dart';
import '../../listings/providers/listing_providers.dart';
import '../../reviews/providers/review_providers.dart';
import '../../interactions/providers/interaction_providers.dart';
import '../../profile/widgets/public_profile_link.dart';

class ListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));
    final reviewsAsync = ref.watch(listingReviewsProvider(listingId));

    return Scaffold(
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load listing: $error'),
              TextButton(
                onPressed: () => ref.refresh(listingDetailProvider(listingId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (place) {
          final images = place.imageUrls.isNotEmpty ? place.imageUrls : [place.imageUrl];

          return CustomScrollView(
            slivers: [
              // Hero Image / Carousel
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        cacheWidth: 1200,
                        gaplessPlayback: true,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return ColoredBox(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => ColoredBox(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  Consumer(
                    builder: (context, ref, child) {
                      final likeCountAsync = ref.watch(itemLikeCountProvider('place:$listingId'));
                      final likeCount = likeCountAsync.value ?? 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (likeCount > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                '$likeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                ),
                              ),
                            ),
                          Consumer(builder: (context, ref, _) {
                            final userLikes = ref.watch(userLikesProvider).value ?? {};
                            final isLiked = userLikes.contains(listingId);
                            return IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isLiked ? Colors.red : Colors.white,
                                shadows: isLiked ? [] : const [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                              onPressed: () async {
                                try {
                                  await ref.read(userLikesProvider.notifier).toggleLike(listingId, 'place');
                                } catch (e) {
                                  if (e.toString().contains('auth_required')) {
                                    if (!context.mounted) return;
                                    context.push('/login');
                                  }
                                }
                              },
                            );
                          }),
                          Consumer(builder: (context, ref, _) {
                            final userBookmarks = ref.watch(userBookmarksProvider).value ?? {};
                            final isBookmarked = userBookmarks.contains(listingId);
                            return IconButton(
                              icon: Icon(
                                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: isBookmarked ? Theme.of(context).primaryColor : Colors.white,
                                shadows: isBookmarked ? [] : const [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                              onPressed: () async {
                                try {
                                  await ref.read(userBookmarksProvider.notifier).toggleBookmark(listingId, 'place');
                                } catch (e) {
                                  if (e.toString().contains('auth_required')) {
                                    if (!context.mounted) return;
                                    context.push('/login');
                                  }
                                }
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                    onPressed: () {},
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Row
                      Row(
                        children: [
                          if (place.isSponsored) ...[
                            const InfoChip(
                              icon: Icons.star,
                              label: 'Sponsored',
                              color: Colors.amber,
                              backgroundColor: Color(0xFFFFF8E1),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (place.isVerified)
                            InfoChip(
                              icon: Icons.verified,
                              label: 'Verified',
                              color: Theme.of(context).colorScheme.primary,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            ),
                        ],
                      ),
                      if (place.isSponsored || place.isVerified) const SizedBox(height: 12),

                      // Title
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PublicProfileLink(
                        userId: place.userId,
                        name: place.creator.displayName,
                        username: place.creator.username,
                        avatarUrl: place.creator.avatarUrl,
                        subtitle: 'Added by local creator',
                      ),
                      const SizedBox(height: 12),

                      // Rating Summary
                      RatingSummaryWidget(rating: place.rating, reviewCount: place.reviewCount),
                      const SizedBox(height: 16),

                      // Address and Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              place.address.isNotEmpty ? place.address : 'Address not available',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            place.openingHours,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const Spacer(),
                          Text(
                            place.priceRange,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      const ActionButtonRow(),
                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'About',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place.description,
                        style: TextStyle(height: 1.5, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 32),

                      // Reviews Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reviews',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push('/listing/$listingId/reviews');
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Live Supabase review preview
                      reviewsAsync.when(
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'No reviews yet. Be the first to review this place.',
                              ),
                            );
                          }
                          return Column(
                            children: reviews.take(3).map((r) => ReviewPreviewCard(review: r)).toList(),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Error loading reviews: $error'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => ref.refresh(listingReviewsProvider(listingId)),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Write Review Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push('/listing/$listingId/write-review');
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Write a Review'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Report Issue Button
                      Center(
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.flag, color: Colors.redAccent, size: 18),
                          label: const Text(
                            'Report an issue with this listing',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

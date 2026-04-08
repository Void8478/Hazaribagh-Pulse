import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/rating_summary_widget.dart';
import '../widgets/action_button_row.dart';
import '../widgets/review_preview_card.dart';
import '../widgets/info_chip.dart';
import '../../listings/providers/listing_providers.dart';
import '../../reviews/providers/review_providers.dart';
import '../../auth/services/auth_provider.dart';
import '../../bookmarks/providers/bookmark_providers.dart';
import '../../profile/providers/profile_providers.dart';

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
                      );
                    },
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {},
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final hasAuth = ref.watch(authStateChangesProvider).value != null;
                      final userProfileAsync = ref.watch(userProfileProvider);
                      final isSaved = userProfileAsync.value?.savedPlaceIds.contains(listingId) ?? false;
                      
                      return IconButton(
                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
                        onPressed: () {
                          if (!hasAuth) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to save places!')));
                           return;
                          }
                          final user = userProfileAsync.value;
                          if (user != null) {
                            ref.read(bookmarkRepositoryProvider).toggleSavedPlace(user.id, listingId, !isSaved);
                          }
                        },
                      );
                    },
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
                      
                      // Live Firestore Review Preview
                      reviewsAsync.when(
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text('No reviews yet. Be the first to review!'),
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
                        error: (error, stack) => Text('Error loading reviews: $error'),
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

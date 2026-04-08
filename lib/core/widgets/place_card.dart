import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/place_model.dart';
import '../../features/interactions/providers/interaction_providers.dart';

class PlaceCard extends ConsumerWidget {
  final PlaceModel place;
  final double width;

  const PlaceCard({
    super.key,
    required this.place,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final likesAsync = ref.watch(userLikesProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);

    final isLiked = likesAsync.value?.contains(place.id) ?? false;
    final isBookmarked = bookmarksAsync.value?.contains(place.id) ?? false;

    return GestureDetector(
      onTap: () {
        context.push('/listing/${place.id}');
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 4.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Theme.of(context).cardTheme.shape is RoundedRectangleBorder
              ? Border.fromBorderSide((Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side)
              : null,
          boxShadow: Theme.of(context).cardTheme.elevation! > 0 ? [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
                    place.imageUrl,
                    height: 120,
                    width: width,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    cacheWidth: 420,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        width: width,
                        color: colorScheme.surfaceContainerHighest,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      width: width,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image_not_supported, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  if (place.isSponsored)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Text(
                          'Sponsored',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.category,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${place.rating} (${place.reviewCount})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Consumer(
                        builder: (context, ref, child) {
                          final likeCountAsync = ref.watch(itemLikeCountProvider('place:${place.id}'));
                          final likeCount = likeCountAsync.value ?? 0;
                          return Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                                  size: 18, 
                                  color: isLiked ? Colors.red : colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () async {
                                  try {
                                    await ref.read(userLikesProvider.notifier).toggleLike(place.id, 'place');
                                  } catch (e) {
                                    if (e.toString().contains('auth_required')) {
                                      if (!context.mounted) return;
                                      context.push('/login');
                                    }
                                  }
                                },
                              ),
                              if (likeCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: Text(
                                    '$likeCount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: Icon(
                          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                          size: 18, 
                          color: isBookmarked ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(userBookmarksProvider.notifier).toggleBookmark(place.id, 'place');
                          } catch (e) {
                            if (e.toString().contains('auth_required')) {
                              if (!context.mounted) return;
                              context.push('/login');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

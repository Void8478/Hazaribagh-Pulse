import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/event_model.dart';
import '../../interactions/providers/interaction_providers.dart';

class EventCard extends ConsumerWidget {
  final EventModel event;

  const EventCard({
    super.key,
    required this.event,
  });

  String _getMonthName(int month) {
    const monthNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final likesAsync = ref.watch(userLikesProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);

    final isLiked = likesAsync.value?.contains(event.id) ?? false;
    final isBookmarked = bookmarksAsync.value?.contains(event.id) ?? false;

    return GestureDetector(
      onTap: () {
        context.push('/event/${event.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0, right: 4.0),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: theme.cardTheme.shape is RoundedRectangleBorder
              ? Border.fromBorderSide((theme.cardTheme.shape as RoundedRectangleBorder).side)
              : null,
          boxShadow: theme.cardTheme.elevation! > 0 ? [
            BoxShadow(
              color: theme.cardTheme.shadowColor ?? Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Badges
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
                    event.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    cacheWidth: 720,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: colorScheme.surfaceContainerHighest,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      width: double.infinity,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image_not_supported, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.isFree ? Colors.green.shade600 : colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        event.isFree ? 'Free' : event.price,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light ? Colors.white.withAlpha(230) : Colors.black.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getMonthName(event.date.month),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            event.date.day.toString(),
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.category.toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        event.time,
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final likeCountAsync = ref.watch(itemLikeCountProvider('event:${event.id}'));
                          final likeCount = likeCountAsync.value ?? 0;
                          return Row(
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                                  size: 24, 
                                  color: isLiked ? Colors.red : colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () async {
                                  try {
                                    await ref.read(userLikesProvider.notifier).toggleLike(event.id, 'event');
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
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    '$likeCount',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                          size: 24, 
                          color: isBookmarked ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(userBookmarksProvider.notifier).toggleBookmark(event.id, 'event');
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
            ),
          ],
        ),
      ),
    );
  }
}

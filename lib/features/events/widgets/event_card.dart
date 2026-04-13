import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/content_display.dart';
import '../../../../models/event_model.dart';
import '../../interactions/providers/interaction_providers.dart';
import '../../profile/widgets/public_profile_link.dart';

class EventCard extends ConsumerWidget {
  const EventCard({
    super.key,
    required this.event,
  });

  final EventModel event;

  String _getMonthName(int month) {
    const monthNames = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final likesAsync = ref.watch(userLikesProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);

    final isLiked =
        likesAsync.value?.contains(interactionKey('event', event.id)) ?? false;
    final isBookmarked = bookmarksAsync.value
            ?.contains(interactionKey('event', event.id)) ??
        false;

    final dateLabel = event.startDateOrNull == null
        ? 'TBA'
        : _getMonthName(event.startDate.month);

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 6),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (event.imageUrl.trim().isNotEmpty)
                  Image.network(
                    event.imageUrl,
                    height: 182,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    cacheWidth: 760,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 182,
                        width: double.infinity,
                        color: colorScheme.surfaceContainerHighest,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 182,
                      width: double.infinity,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 182,
                    width: double.infinity,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.event_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 40,
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    width: 54,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dateLabel,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.startDateOrNull == null ? '--' : '${event.startDate.day}',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: event.isFree
                          ? const Color(0xFF1D8A63)
                          : colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      event.priceLabel,
                      style: TextStyle(
                        color: event.isFree ? Colors.white : colorScheme.onPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (event.isFeatured)
                        _EventPill(
                          label: 'FEATURED',
                          icon: Icons.workspace_premium_rounded,
                          color: const Color(0xFF1D3B7A),
                        ),
                      _EventPill(
                        label: event.categoryLabel.toUpperCase(),
                        icon: Icons.sell_outlined,
                        color: colorScheme.secondary,
                      ),
                      _EventPill(
                        label: event.timeLabel,
                        icon: Icons.schedule_rounded,
                        color: colorScheme.primary,
                      ),
                      _EventPill(
                        label: formatMediumDate(event.startDateOrNull),
                        icon: Icons.event_rounded,
                        color: colorScheme.tertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PublicProfileLink(
                    userId: event.userId,
                    name: event.creator.displayName,
                    username: event.creator.username,
                    avatarUrl: event.creator.avatarUrl,
                    subtitle: event.organizerLabel,
                    compact: true,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.locationLabel.isEmpty
                              ? 'Location will be announced'
                              : event.locationLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final likeCountAsync =
                              ref.watch(itemLikeCountProvider('event:${event.id}'));
                          final likeCount = likeCountAsync.value ?? 0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionIcon(
                                icon: isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isLiked
                                    ? const Color(0xFFE25555)
                                    : colorScheme.onSurfaceVariant,
                                onTap: () async {
                                  try {
                                    await ref
                                        .read(userLikesProvider.notifier)
                                        .toggleLike(event.id, 'event');
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
                                  padding: const EdgeInsets.only(left: 4, right: 8),
                                  child: Text(
                                    '$likeCount',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              _ActionIcon(
                                icon: isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: isBookmarked
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                onTap: () async {
                                  try {
                                    await ref
                                        .read(userBookmarksProvider.notifier)
                                        .toggleBookmark(event.id, 'event');
                                  } catch (e) {
                                    if (e.toString().contains('auth_required')) {
                                      if (!context.mounted) return;
                                      context.push('/login');
                                    }
                                  }
                                },
                              ),
                            ],
                          );
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

class _EventPill extends StatelessWidget {
  const _EventPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

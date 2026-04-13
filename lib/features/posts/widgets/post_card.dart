import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/post_model.dart';
import '../../interactions/providers/interaction_providers.dart';
import '../../profile/widgets/public_profile_link.dart';

class PostCard extends ConsumerWidget {
  const PostCard({
    super.key,
    required this.post,
    this.width = 292,
  });

  final PostModel post;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final likesAsync = ref.watch(userLikesProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);

    final isLiked =
        likesAsync.value?.contains(interactionKey('post', post.id)) ?? false;
    final isBookmarked = bookmarksAsync.value
            ?.contains(interactionKey('post', post.id)) ??
        false;

    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(left: 16, right: 6, bottom: 10),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrl.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    post.imageUrl,
                    height: 130,
                    width: width,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    cacheWidth: 600,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 130,
                        width: width,
                        color: colorScheme.surfaceContainerHighest,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 130,
                      width: width,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.20),
                          ],
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
                      if (post.categoryName.isNotEmpty)
                        _PillLabel(
                          label: post.categoryName,
                          color: colorScheme.primary,
                        ),
                      if (post.location.isNotEmpty)
                        _PillLabel(
                          label: post.location,
                          color: colorScheme.secondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                      height: 1.15,
                    ),
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  PublicProfileLink(
                    userId: post.userId,
                    name: post.creator.displayName,
                    username: post.creator.username,
                    avatarUrl: post.creator.avatarUrl,
                    subtitle: post.createdAt != null
                        ? '${post.createdAt!.day}/${post.createdAt!.month}/${post.createdAt!.year}'
                        : post.creator.usernameLabel,
                    compact: true,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final likeCountAsync =
                              ref.watch(itemLikeCountProvider('post:${post.id}'));
                          final likeCount = likeCountAsync.value ?? 0;
                          return Row(
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
                                        .toggleLike(post.id, 'post');
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
                                  padding: const EdgeInsets.only(left: 4, right: 10),
                                  child: Text(
                                    '$likeCount',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
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
                                .toggleBookmark(post.id, 'post');
                          } catch (e) {
                            if (e.toString().contains('auth_required')) {
                              if (!context.mounted) return;
                              context.push('/login');
                            }
                          }
                        },
                      ),
                      const Spacer(),
                      Text(
                        'Open',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: colorScheme.primary,
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

class _PillLabel extends StatelessWidget {
  const _PillLabel({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
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

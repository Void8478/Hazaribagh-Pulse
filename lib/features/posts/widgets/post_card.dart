import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/post_model.dart';
import '../../interactions/providers/interaction_providers.dart';

class PostCard extends ConsumerWidget {
  const PostCard({
    super.key,
    required this.post,
    this.width = 280,
  });

  final PostModel post;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final likesAsync = ref.watch(userLikesProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);

    final isLiked = likesAsync.value?.contains(post.id) ?? false;
    final isBookmarked = bookmarksAsync.value?.contains(post.id) ?? false;

    return GestureDetector(
      onTap: () {
        context.push('/post/${post.id}');
      },
      child: Container(
        width: width,
      margin: const EdgeInsets.only(left: 16, right: 4, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                post.imageUrl,
                height: 120,
                width: width,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                cacheWidth: 560,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
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
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.categoryName.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      post.categoryName,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (post.categoryName.isNotEmpty) const SizedBox(height: 12),
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    post.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (post.location.isNotEmpty) 
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                post.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else 
                      const Spacer(),
                    Row(
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final likeCountAsync = ref.watch(itemLikeCountProvider('post:${post.id}'));
                            final likeCount = likeCountAsync.value ?? 0;
                            return Row(
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: Icon(
                                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 20,
                                    color: isLiked ? Colors.red : colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await ref.read(userLikesProvider.notifier).toggleLike(post.id, 'post');
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
                                    padding: const EdgeInsets.only(right: 8.0),
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
                            size: 20,
                            color: isBookmarked ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () async {
                            try {
                              await ref.read(userBookmarksProvider.notifier).toggleBookmark(post.id, 'post');
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
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}


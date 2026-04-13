import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comments/services/supabase_comment_service.dart';
import '../../comments/widgets/comment_section.dart';
import '../../listings/widgets/info_chip.dart';
import '../providers/post_providers.dart';
import '../../interactions/providers/interaction_providers.dart';
import '../../profile/widgets/public_profile_link.dart';
import 'package:go_router/go_router.dart';

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  String _formatDate(DateTime date) {
    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsyncValue = ref.watch(postDetailProvider(postId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final userLikes = ref.watch(userLikesProvider).value ?? {};
    final userBookmarks = ref.watch(userBookmarksProvider).value ?? {};
    final isLiked = userLikes.contains(interactionKey('post', postId));
    final isBookmarked = userBookmarks.contains(interactionKey('post', postId));
    
    final likeCountAsync = ref.watch(itemLikeCountProvider('post:$postId'));
    final likeCount = likeCountAsync.value ?? 0;

    return Scaffold(
      body: postAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load post: $err'),
              TextButton(
                onPressed: () => ref.refresh(postDetailProvider(postId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (post) {
          final timeAgoStr = post.createdAt != null
              ? _formatDate(post.createdAt!)
              : 'Unknown date';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: post.imageUrl.isNotEmpty
                      ? Image.network(
                          post.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.image_not_supported_outlined,
                                  size: 48),
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.article_outlined, size: 64),
                          ),
                        ),
                ),
                actions: [
                  if (likeCount > 0)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Text(
                          '$likeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? Colors.red : Colors.white,
                      shadows: isLiked ? [] : const [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    onPressed: () async {
                      try {
                        await ref.read(userLikesProvider.notifier).toggleLike(postId, 'post');
                      } catch (e) {
                        if (e.toString().contains('auth_required')) {
                          if (!context.mounted) return;
                          context.push('/login');
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isBookmarked ? theme.primaryColor : Colors.white,
                      shadows: isBookmarked ? [] : const [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    onPressed: () async {
                      try {
                        await ref.read(userBookmarksProvider.notifier).toggleBookmark(postId, 'post');
                      } catch (e) {
                        if (e.toString().contains('auth_required')) {
                          if (!context.mounted) return;
                          context.push('/login');
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (post.categoryName.isNotEmpty)
                            InfoChip(
                              icon: Icons.category,
                              label: post.categoryName,
                              color: colorScheme.primary,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                            ),
                          Text(
                            timeAgoStr,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        post.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PublicProfileLink(
                        userId: post.userId,
                        name: post.creator.displayName,
                        username: post.creator.username,
                        avatarUrl: post.creator.avatarUrl,
                        subtitle: 'Creator',
                      ),
                      const SizedBox(height: 24),
                      if (post.location.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, color: colorScheme.primary, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                post.location,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        post.description,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CommentSection(
                        title: 'Comments',
                        target: CommentTarget(
                          type: CommentTargetType.post,
                          contentId: post.id,
                        ),
                        emptyTitle: 'No comments yet',
                        emptySubtitle: 'Be the first local voice on this post.',
                      ),
                      const SizedBox(height: 48),
                      // Add padding to ensure content isn't under any bottom nav
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

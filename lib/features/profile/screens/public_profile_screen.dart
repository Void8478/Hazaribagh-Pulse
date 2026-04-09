import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../../models/post_model.dart';
import '../../../models/user_model.dart';
import '../../../core/widgets/place_card.dart';
import '../../events/widgets/event_card.dart';
import '../../posts/widgets/post_card.dart';
import '../providers/public_profile_providers.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicUserProfileProvider(userId));

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _PublicProfileError(
          message: 'Failed to load profile',
          details: '$error',
          onRetry: () => ref.invalidate(publicUserProfileProvider(userId)),
        ),
        data: (user) {
          final postsAsync = ref.watch(publicUserPostsProvider(userId));
          final listingsAsync = ref.watch(publicUserListingsProvider(userId));
          final eventsAsync = ref.watch(publicUserEventsProvider(userId));
          final postCount = postsAsync.maybeWhen(
            data: (items) => items.length,
            orElse: () => null,
          );
          final listingCount = listingsAsync.maybeWhen(
            data: (items) => items.length,
            orElse: () => null,
          );
          final eventCount = eventsAsync.maybeWhen(
            data: (items) => items.length,
            orElse: () => null,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                pinned: true,
                title: Text(user.fullName),
              ),
              SliverToBoxAdapter(
                child: _PublicProfileHeader(
                  user: user,
                  postCount: postCount,
                  listingCount: listingCount,
                  eventCount: eventCount,
                ),
              ),
              SliverToBoxAdapter(
                child: _PublicSection<PostModel>(
                  title: 'Posts',
                  emptyTitle: 'No posts yet',
                  itemsAsync: postsAsync,
                  onRetry: () => ref.invalidate(publicUserPostsProvider(userId)),
                  itemBuilder: (post) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: PostCard(post: post, width: double.infinity),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _PublicSection<PlaceModel>(
                  title: 'Places',
                  emptyTitle: 'No places yet',
                  itemsAsync: listingsAsync,
                  onRetry: () => ref.invalidate(publicUserListingsProvider(userId)),
                  itemBuilder: (place) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: PlaceCard(place: place, width: double.infinity),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _PublicSection<EventModel>(
                  title: 'Events',
                  emptyTitle: 'No events yet',
                  itemsAsync: eventsAsync,
                  onRetry: () => ref.invalidate(publicUserEventsProvider(userId)),
                  itemBuilder: (event) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: EventCard(event: event),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          );
        },
      ),
    );
  }
}

class _PublicProfileHeader extends StatelessWidget {
  const _PublicProfileHeader({
    required this.user,
    this.postCount,
    this.listingCount,
    this.eventCount,
  });

  final UserModel user;
  final int? postCount;
  final int? listingCount;
  final int? eventCount;

  String _joinedLabel() {
    final createdAt = user.createdAt;
    if (createdAt == null) return 'Recently joined';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Joined ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usernameLabel = user.username.trim().isNotEmpty ? '@${user.username.trim()}' : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.12),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? NetworkImage(user.avatarUrl)
                    : null,
                child: user.avatarUrl.isEmpty
                    ? Icon(Icons.person, size: 34, color: colorScheme.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (usernameLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        usernameLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _joinedLabel(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              user.bio.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.86),
              ),
            ),
          ],
          if (user.location.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.location.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _StatPill(label: 'Posts', value: postCount),
              const SizedBox(width: 10),
              _StatPill(label: 'Places', value: listingCount),
              const SizedBox(width: 10),
              _StatPill(label: 'Events', value: eventCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value?.toString() ?? '--',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicSection<T> extends StatelessWidget {
  const _PublicSection({
    required this.title,
    required this.emptyTitle,
    required this.itemsAsync,
    required this.onRetry,
    required this.itemBuilder,
  });

  final String title;
  final String emptyTitle;
  final AsyncValue<List<T>> itemsAsync;
  final VoidCallback onRetry;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          itemsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => _PublicProfileError(
              message: 'Failed to load $title',
              details: '$error',
              onRetry: onRetry,
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      emptyTitle,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return Column(
                children: items.map(itemBuilder).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PublicProfileError extends StatelessWidget {
  const _PublicProfileError({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              details,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

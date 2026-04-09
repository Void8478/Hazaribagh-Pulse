import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/create_bottom_sheet.dart';
import '../../../core/widgets/place_card.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../events/widgets/event_card.dart';
import '../providers/home_providers.dart';
import '../../notifications/widgets/notification_bell_button.dart';
import '../../posts/widgets/post_card.dart';
import '../../../models/post_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildHorizontalList(List<PlaceModel> places) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        cacheExtent: 560,
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: PlaceCard(place: places[index]),
          );
        },
      ),
    );
  }

  Widget _buildEventsList(List<EventModel> events) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        cacheExtent: 560,
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 280,
              child: RepaintBoundary(
                child: EventCard(event: events[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList(List<PostModel> posts) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        cacheExtent: 560,
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: PostCard(post: posts[index]),
          );
        },
      ),
    );
  }

  Widget _buildPlaceRailLoader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemBuilder: (context, index) {
          return _RailSkeletonCard(
            width: 214,
            height: 214,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
          );
        },
      ),
    );
  }

  Widget _buildEventRailLoader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemBuilder: (context, index) {
          return _RailSkeletonCard(
            width: 280,
            height: 260,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
          );
        },
      ),
    );
  }

  Widget _buildPostRailLoader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemBuilder: (context, index) {
          return _RailSkeletonCard(
            width: 292,
            height: 228,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
          );
        },
      ),
    );
  }

  Widget _buildSectionError(
    BuildContext context,
    WidgetRef ref,
    String message,
    dynamic provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PremiumEmptyState(
        icon: Icons.cloud_off_rounded,
        title: message,
        subtitle: 'Please check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(provider),
      ),
    );
  }

  Widget _buildSectionEmpty(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return PremiumEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(homeTrendingListingsProvider);
    final topRatedAsync = ref.watch(homeTopRatedListingsProvider);
    final eventsAsync = ref.watch(homeUpcomingEventsProvider);
    final hiddenGemsAsync = ref.watch(homeHiddenGemListingsProvider);
    final postsAsync = ref.watch(homeRecentPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hazaribagh Pulse',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => showCreateSheet(context),
          ),
          const NotificationBellButton(),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => context.go('/explore'),
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.34),
                      ],
                    ),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search places, posts, and events',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SectionHeader(
              title: 'Community Updates',
              subtitle: 'Recent stories and updates from people around you.',
            ),
            postsAsync.when(
              loading: () => _buildPostRailLoader(context),
              error: (err, _) => _buildSectionError(
                context,
                ref,
                'Could not load community updates',
                homeRecentPostsProvider,
              ),
              data: (posts) => posts.isEmpty
                  ? _buildSectionEmpty(
                      Icons.campaign_outlined,
                      'No community updates yet',
                      'Fresh posts from local users will appear here.',
                    )
                  : _buildPostsList(posts),
            ),
            SectionHeader(
              title: 'Trending Near You',
              subtitle: 'Places locals are opening, sharing, and saving right now.',
              onSeeAll: () => context.go('/explore'),
            ),
            trendingAsync.when(
              loading: () => _buildPlaceRailLoader(context),
              error: (err, _) => _buildSectionError(
                context,
                ref,
                'Could not load trending places',
                homeTrendingListingsProvider,
              ),
              data: (places) => places.isEmpty
                  ? _buildSectionEmpty(
                      Icons.local_fire_department_outlined,
                      'No trending places yet',
                      'Fresh local recommendations will appear here.',
                    )
                  : _buildHorizontalList(places),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Top Rated Services',
              subtitle: 'Reliable places with strong reviews and repeat trust.',
              onSeeAll: () => context.go('/explore'),
            ),
            topRatedAsync.when(
              loading: () => _buildPlaceRailLoader(context),
              error: (err, _) => _buildSectionError(
                context,
                ref,
                'Could not load top rated places',
                homeTopRatedListingsProvider,
              ),
              data: (places) => places.isEmpty
                  ? _buildSectionEmpty(
                      Icons.star_outline_rounded,
                      'No top rated places yet',
                      'Ratings and reviews will surface the best spots here.',
                    )
                  : _buildHorizontalList(places),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Upcoming Events',
              subtitle: 'A quick look at what is happening soon in the city.',
              onSeeAll: () => context.go('/events'),
            ),
            eventsAsync.when(
              loading: () => _buildEventRailLoader(context),
              error: (err, _) => _buildSectionError(
                context,
                ref,
                'Could not load upcoming events',
                homeUpcomingEventsProvider,
              ),
              data: (events) => events.isEmpty
                  ? _buildSectionEmpty(
                      Icons.event_busy_outlined,
                      'No upcoming events yet',
                      'New local events will show up here as they are added.',
                    )
                  : _buildEventsList(events),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Hidden Gems',
              subtitle: 'Quiet favorites worth discovering before everyone else finds them.',
              onSeeAll: () => context.go('/explore'),
            ),
            hiddenGemsAsync.when(
              loading: () => _buildPlaceRailLoader(context),
              error: (err, _) => _buildSectionError(
                context,
                ref,
                'Could not load hidden gems',
                homeHiddenGemListingsProvider,
              ),
              data: (places) => places.isEmpty
                  ? _buildSectionEmpty(
                      Icons.diamond_outlined,
                      'No hidden gems yet',
                      'Lower-profile local favorites will appear here.',
                    )
                  : _buildHorizontalList(places),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RailSkeletonCard extends StatelessWidget {
  const _RailSkeletonCard({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 14, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.55),
          ],
        ),
      ),
    );
  }
}

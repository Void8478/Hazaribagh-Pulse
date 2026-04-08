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
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (context, index) {
          return PlaceCard(place: places[index]);
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
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 280,
              child: EventCard(event: events[index]),
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
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
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
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
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
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
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
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
            ),
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                readOnly: true,
                onTap: () => context.go('/explore'),
                decoration: InputDecoration(
                  hintText: 'Search for cafes, plumbers, events...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            const SectionHeader(
              title: 'Community Updates',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../comments/services/supabase_comment_service.dart';
import '../../comments/widgets/comment_section.dart';
import '../../listings/widgets/info_chip.dart';
import '../providers/event_providers.dart';
import '../../interactions/providers/interaction_providers.dart';
import 'package:go_router/go_router.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  String _formatDate(DateTime date) {
    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return '${weekdayNames[date.weekday - 1]}, ${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsyncValue = ref.watch(eventDetailProvider(eventId));
    final theme = Theme.of(context);
    
    final userLikes = ref.watch(userLikesProvider).value ?? {};
    final userBookmarks = ref.watch(userBookmarksProvider).value ?? {};
    final isLiked = userLikes.contains(eventId);
    final isBookmarked = userBookmarks.contains(eventId);
    
    final likeCountAsync = ref.watch(itemLikeCountProvider('event:$eventId'));
    final likeCount = likeCountAsync.value ?? 0;

    return Scaffold(
      body: eventAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load event: $err'),
              TextButton(
                onPressed: () => ref.refresh(eventDetailProvider(eventId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (event) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
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
                        await ref.read(userLikesProvider.notifier).toggleLike(eventId, 'event');
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
                        await ref.read(userBookmarksProvider.notifier).toggleBookmark(eventId, 'event');
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InfoChip(
                            icon: Icons.category,
                            label: event.category,
                            color: Theme.of(context).colorScheme.primary,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: 8),
                          InfoChip(
                            icon: Icons.local_activity,
                            label: event.isFree ? 'Free Event' : event.price,
                            color: event.isFree ? Colors.green : Colors.orange,
                            backgroundColor: event.isFree ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'By ${event.organizer}',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      _buildIconRow(context, Icons.calendar_today, 'Date and Time', '${_formatDate(event.date)}\n${event.time}'),
                      const SizedBox(height: 16),
                      _buildIconRow(context, Icons.location_on, 'Location', '${event.location}\n${event.address}'),
                      const SizedBox(height: 32),
                      const Text('About this event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: TextStyle(height: 1.5, color: Colors.grey.shade800, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      CommentSection(
                        title: 'Discussion',
                        target: CommentTarget(
                          type: CommentTargetType.event,
                          contentId: event.id,
                        ),
                        emptyTitle: 'No discussion yet',
                        emptySubtitle: 'Ask a question or share what people should know before going.',
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.star_border), // Interested button
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('RSVP / Get Tickets logic would go here.')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Get Tickets / RSVP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconRow(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

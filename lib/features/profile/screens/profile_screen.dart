import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/place_card.dart';
import '../../auth/services/auth_provider.dart';
import '../../bookmarks/providers/bookmark_providers.dart';
import '../../events/widgets/event_card.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_menu_tiles.dart';
import '../widgets/saved_items_section.dart';
import '../widgets/user_header.dart';
import '../widgets/user_reviews_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);

      if (next.error != null && previous?.error != next.error) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final userProfileAsync = ref.watch(userProfileProvider);
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final savedEventsAsync = ref.watch(savedEventsProvider);
    final accountActionInFlight =
        authState.isSigningOut || authState.isDeletingAccount;

    return Stack(
      children: [
        Scaffold(
          body: userProfileAsync.when(
            loading: () => _buildLoadingSkeleton(context),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 52,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'We could not load your account right now.',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$err',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(userProfileProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
            data: (user) {
              if (user == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 52,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your profile is not available yet.',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please refresh once your session is stable.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.tonal(
                          onPressed: () => ref.invalidate(userProfileProvider),
                          child: const Text('Refresh Profile'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final userReviewsAsync = ref.watch(userReviewsProvider(user.id));
              final reviewsCount =
                  userReviewsAsync.value?.length ?? user.reviewsCount;
              final photosCount =
                  userReviewsAsync.value?.fold<int>(
                        0,
                        (sum, review) => sum + review.imageUrls.length,
                      ) ??
                      user.photosCount;
              final savedCount =
                  savedPlacesAsync.value?.length ?? user.savedPlaceIds.length;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    title: Text(
                      'Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    floating: true,
                    backgroundColor: Colors.transparent,
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserHeader(
                          user: user,
                          reviewsCountOverride: reviewsCount,
                          savedCountOverride: savedCount,
                          photosCountOverride: photosCount,
                        ),
                        const SizedBox(height: 28),
                        savedPlacesAsync.when(
                          data: (places) => SavedItemsSection(
                            title: 'Saved Places',
                            items: places,
                            emptyTitle: 'No saved places yet',
                            emptySubtitle:
                                'Explore and bookmark your favorite spots!',
                            itemBuilder: (place) => SizedBox(
                              width: 280,
                              child: PlaceCard(place: place),
                            ),
                          ),
                          loading: () => _buildSectionLoader(context),
                          error: (err, stack) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Could not load saved places.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        savedEventsAsync.when(
                          data: (events) => SavedItemsSection(
                            title: 'Saved Events',
                            items: events,
                            emptyIcon: 'event',
                            emptyTitle: 'No saved events yet',
                            emptySubtitle:
                                'Save upcoming events to never miss out!',
                            itemBuilder: (event) => SizedBox(
                              width: 280,
                              child: EventCard(event: event),
                            ),
                          ),
                          loading: () => _buildSectionLoader(context),
                          error: (err, stack) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Could not load saved events.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        UserReviewsSection(userId: user.id),
                        const SizedBox(height: 32),
                        ProfileMenuTiles(
                          onLogout: accountActionInFlight
                              ? () {}
                              : () => _showLogoutDialog(context),
                          onDeleteAccount: accountActionInFlight
                              ? () {}
                              : () => _showDeleteDialog(context),
                          isLoggingOut: authState.isSigningOut,
                          isDeletingAccount: authState.isDeletingAccount,
                          actionsDisabled: accountActionInFlight,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (authState.isSigningOut) _AccountActionOverlay(message: 'Logging you out...'),
        if (authState.isDeletingAccount)
          _AccountActionOverlay(
            message: 'Deleting your account permanently...',
          ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to log out from this device?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        var typedText = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                  const SizedBox(width: 8),
                  const Text('Delete Account'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will permanently delete your account, profile, posts, places, events, reviews, comments, saves, likes, notifications, and associated authentication data. This cannot be undone.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'After confirmation, your account will be erased from this app permanently.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type "DELETE" below to confirm:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (val) => setState(() => typedText = val),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'DELETE',
                    ),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                  ),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: typedText == 'DELETE'
                      ? () => Navigator.of(ctx).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldDelete == true && mounted) {
      await ref.read(authProvider.notifier).deleteAccount();
    }
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 160,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLoader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _AccountActionOverlay extends StatelessWidget {
  const _AccountActionOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.2),
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

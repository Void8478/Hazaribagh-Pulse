import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/place_card.dart';
import '../../events/widgets/event_card.dart';
import '../widgets/user_header.dart';
import '../widgets/saved_items_section.dart';
import '../widgets/profile_menu_tiles.dart';
import '../widgets/user_reviews_section.dart';
import '../../auth/services/auth_provider.dart';
import '../../bookmarks/providers/bookmark_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error == 'requires-recent-login' && previous?.error != 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('For security reasons, you must re-authenticate. Please log in again to delete your account.'),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (next.error != null && previous?.error != next.error && next.error != 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });

    final userProfileAsync = ref.watch(userProfileProvider);
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final savedEventsAsync = ref.watch(savedEventsProvider);

    return Scaffold(
      body: userProfileAsync.when(
        loading: () => _buildLoadingSkeleton(context),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading profile', style: TextStyle(color: colorScheme.onSurface, fontSize: 16)),
              const SizedBox(height: 8),
              Text('$err', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('User profile not found.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

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
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: colorScheme.onSurfaceVariant),
                    onPressed: () {
                      // Scroll to settings section
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserHeader(user: user),
                    const SizedBox(height: 28),
                    
                    // Saved Places — Firestore
                    savedPlacesAsync.when(
                      data: (places) => SavedItemsSection(
                        title: 'Saved Places',
                        items: places,
                        emptyTitle: 'No saved places yet',
                        emptySubtitle: 'Explore and bookmark your favorite spots!',
                        itemBuilder: (place) => SizedBox(
                          width: 280,
                          child: PlaceCard(place: place),
                        ),
                      ),
                      loading: () => _buildSectionLoader(context),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("Could not load saved places", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Saved Events — Firestore with mock fallback
                    savedEventsAsync.when(
                      data: (events) => SavedItemsSection(
                        title: 'Saved Events',
                        items: events,
                        emptyIcon: 'event',
                        emptyTitle: 'No saved events yet',
                        emptySubtitle: 'Save upcoming events to never miss out!',
                        itemBuilder: (event) => SizedBox(
                          width: 280,
                          child: EventCard(event: event),
                        ),
                      ),
                      loading: () => _buildSectionLoader(context),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("Could not load saved events", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    UserReviewsSection(userId: user.id),
                    const SizedBox(height: 32),
                    
                    ProfileMenuTiles(
                      onLogout: () => _showLogoutDialog(context, ref),
                      onDeleteAccount: () => _showDeleteDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface),
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

    if (shouldLogout == true && context.mounted) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        String typedText = "";
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
                  const Text('This will permanently delete your account, your profile data, and all associated authentications. This cannot be undone.'),
                  const SizedBox(height: 8),
                  Text(
                    'Your reviews will remain visible as "Deleted User".',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  const Text('Type "DELETE" below to confirm:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (val) => setState(() => typedText = val),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'DELETE',
                    ),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: typedText == "DELETE"
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

    if (shouldDelete == true && context.mounted) {
      await ref.read(authProvider.notifier).deleteAccount();
    }
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Avatar skeleton
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            // Name skeleton
            Container(
              width: 160,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            // Email skeleton
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 32),
            // Stats skeleton
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/mock_data.dart';
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

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error == 'requires-recent-login' && previous?.error != 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('For security reasons, you must re-authenticate. Please log in again to delete your account.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (next.error != null && previous?.error != next.error && next.error != 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    final userProfileAsync = ref.watch(userProfileProvider);
    final savedPlacesAsync = ref.watch(savedPlacesProvider);

    return Scaffold(
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User profile not found.'));
          }

          // Convert mock events filtering to rely on user's array (since events aren't fully migrated to DB saves yet)
          final savedEvents = MockData.mockEvents.where((e) => user.savedEventIds.contains(e.id)).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                floating: true,
                actions: [
                  IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserHeader(user: user),
                    const SizedBox(height: 24),
                    
                    // Firestore Saved Places
                    savedPlacesAsync.when(
                      data: (places) => SavedItemsSection(
                        title: 'Saved Places',
                        items: places,
                        itemBuilder: (place) => SizedBox(
                          width: 280,
                          child: PlaceCard(place: place),
                        ),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("Could not load saved places: $err"),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Saved Events (still mock-based, but using real user array)
                    SavedItemsSection(
                      title: 'Saved Events',
                      items: savedEvents,
                      itemBuilder: (event) => SizedBox(
                        width: 280,
                        child: EventCard(event: event),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    UserReviewsSection(userId: user.id),
                    const SizedBox(height: 32),
                    
                    ProfileMenuTiles(
                      onLogout: () async {
                        final bool? shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to logout?'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    foregroundColor: Theme.of(context).colorScheme.onError,
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
                      },
                      onDeleteAccount: () async {
                        final bool? shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            String typedText = "";
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                                      const SizedBox(width: 8),
                                      const Text('Delete Account'),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('This will permanently delete your account, your profile data, and all associated authentications. This cannot be undone.'),
                                      const SizedBox(height: 16),
                                      const Text('Type "DELETE" below to confirm:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        onChanged: (val) {
                                          setState(() => typedText = val);
                                        },
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'DELETE',
                                        ),
                                      ),
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: typedText == "DELETE" 
                                          ? () => Navigator.of(context).pop(true)
                                          : null,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                        foregroundColor: Theme.of(context).colorScheme.onError,
                                      ),
                                      child: const Text('Delete Permanently'),
                                    ),
                                  ],
                                );
                              }
                            );
                          },
                        );

                        if (shouldDelete == true && context.mounted) {
                          await ref.read(authProvider.notifier).deleteAccount();
                        }
                      },
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
}



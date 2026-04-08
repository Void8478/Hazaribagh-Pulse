import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void showCreateSheet(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: colorScheme.surface,
    builder: (sheetContext) {
      Widget tile({
        required IconData icon,
        required String title,
        required String subtitle,
        required String route,
      }) {
        return ListTile(
          leading: Icon(icon, color: colorScheme.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(sheetContext).pop();
            context.push(route);
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile(
                icon: Icons.edit_note_rounded,
                title: 'Create Post',
                subtitle: 'Share a local update or community note',
                route: '/create-post',
              ),
              tile(
                icon: Icons.storefront_rounded,
                title: 'Add Place',
                subtitle: 'Submit a local spot to Explore',
                route: '/create-place',
              ),
              tile(
                icon: Icons.event_available_rounded,
                title: 'Create Event',
                subtitle: 'Publish an event for the community',
                route: '/create-event',
              ),
            ],
          ),
        ),
      );
    },
  );
}

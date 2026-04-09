import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PublicProfileLink extends StatelessWidget {
  const PublicProfileLink({
    super.key,
    required this.userId,
    required this.name,
    this.username = '',
    this.avatarUrl = '',
    this.subtitle,
    this.compact = false,
  });

  final String userId;
  final String name;
  final String username;
  final String avatarUrl;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canOpen = userId.trim().isNotEmpty;
    final label = name.trim().isNotEmpty ? name.trim() : 'User';
    final secondary = subtitle ?? (username.trim().isNotEmpty ? '@$username' : '');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: canOpen ? () => context.push('/users/$userId') : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 4,
          vertical: compact ? 0 : 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: compact ? 16 : 18,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Icon(
                      Icons.person_outline,
                      size: compact ? 16 : 18,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (secondary.isNotEmpty)
                    Text(
                      secondary,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
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

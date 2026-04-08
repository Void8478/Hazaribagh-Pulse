import 'package:flutter/material.dart';

import 'package:hazaribagh_pulse/models/comment_model.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
  });

  final CommentModel comment;

  String _timeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }

    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = comment.authorUsername.isNotEmpty
        ? '@${comment.authorUsername}'
        : _timeAgo(comment.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: comment.authorAvatarUrl.isNotEmpty
                ? NetworkImage(comment.authorAvatarUrl)
                : null,
            child: comment.authorAvatarUrl.isEmpty
                ? Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (comment.authorUsername.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  comment.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

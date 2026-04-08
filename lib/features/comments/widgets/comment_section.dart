import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/auth_provider.dart';
import '../providers/comment_providers.dart';
import '../services/supabase_comment_service.dart';
import 'comment_card.dart';

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({
    super.key,
    required this.title,
    required this.target,
    this.emptyTitle = 'No comments yet',
    this.emptySubtitle = 'Start the conversation.',
  });

  final String title;
  final CommentTarget target;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a comment before posting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(commentRepositoryProvider).createComment(widget.target, text);
      ref.invalidate(commentsProvider(widget.target));
      _controller.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('auth_required')) {
        context.push('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commentsAsync = ref.watch(commentsProvider(widget.target));
    final currentUser = ref.watch(authStateChangesProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              onPressed: () => ref.refresh(commentsProvider(widget.target)),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh comments',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 5,
                enabled: !_isSubmitting && currentUser != null,
                decoration: InputDecoration(
                  hintText: currentUser == null
                      ? 'Log in to join the conversation'
                      : 'Add a thoughtful comment...',
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      currentUser == null
                          ? 'Comments are open to read. Sign in to add yours.'
                          : 'Be kind, helpful, and local.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : currentUser == null
                            ? () => context.push('/login')
                            : _submitComment,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(currentUser == null
                            ? Icons.login_rounded
                            : Icons.send_rounded),
                    label: Text(currentUser == null ? 'Log In' : 'Post'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load comments',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$error',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => ref.refresh(commentsProvider(widget.target)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.emptyTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.emptySubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: comments
                  .map((comment) => CommentCard(comment: comment))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

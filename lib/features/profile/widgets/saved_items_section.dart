import 'package:flutter/material.dart';
import '../../../core/widgets/premium_empty_state.dart';

class SavedItemsSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final String emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onSeeAll;

  const SavedItemsSection({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.emptyIcon = 'bookmark',
    this.emptyTitle = 'Nothing saved yet',
    this.emptySubtitle = 'Start exploring and save your favorite spots!',
    this.onSeeAll,
  });

  IconData _getEmptyIcon() {
    switch (emptyIcon) {
      case 'event':
        return Icons.event_outlined;
      case 'review':
        return Icons.rate_review_outlined;
      default:
        return Icons.bookmark_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (items.isNotEmpty && onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          PremiumEmptyState(
            icon: _getEmptyIcon(),
            title: emptyTitle,
            subtitle: emptySubtitle,
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: itemBuilder(items[index]),
                );
              },
            ),
          ),
      ],
    );
  }
}

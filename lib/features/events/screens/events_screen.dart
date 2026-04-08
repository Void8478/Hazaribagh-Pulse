import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/premium_empty_state.dart';
import '../providers/event_providers.dart';
import '../widgets/event_card.dart';
import '../widgets/event_category_chips.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(allEventsProvider);
    final eventsAsync = ref.watch(categoryEventsProvider(_selectedCategory));

    final categories = allEventsAsync.maybeWhen(
      data: (events) {
        final unique = events
            .map((event) => event.category)
            .where((category) => category.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        return ['All', ...unique];
      },
      orElse: () => const ['All'],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          EventCategoryChips(
            categories: categories,
            selectedCategory: categories.contains(_selectedCategory)
                ? _selectedCategory
                : 'All',
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: PremiumEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load events',
                  subtitle: '$err',
                  actionLabel: 'Retry',
                  onAction: () => ref.refresh(categoryEventsProvider(_selectedCategory)),
                ),
              ),
              data: (filteredEvents) {
                if (filteredEvents.isEmpty) {
                  return const Center(
                    child: PremiumEmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'No events found',
                      subtitle: 'Try another category or create a new event.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    return EventCard(event: filteredEvents[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

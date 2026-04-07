import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/mock_data.dart';
import '../widgets/event_category_chips.dart';
import '../widgets/event_card.dart';
import '../providers/event_providers.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final eventsAsyncValue = ref.watch(categoryEventsProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Event Categories are typically static config, so keeping MockData lookup here is acceptable
          EventCategoryChips(
            categories: MockData.eventCategories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: eventsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading events: $err'),
                    TextButton(
                      onPressed: () => ref.refresh(categoryEventsProvider(_selectedCategory)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (filteredEvents) {
                if (filteredEvents.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No events found in this category.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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


import 'package:flutter/material.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/place_card.dart';
import '../../../models/place_model.dart';
import '../../events/widgets/event_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildHorizontalList(List<PlaceModel> places) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        padding: const EdgeInsets.only(right: 16.0),
        itemBuilder: (context, index) {
          return PlaceCard(place: places[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hazaribagh Pulse', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar (Mock)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for cafes, plumbers, events...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
              ),
            ),
            
            // Trending
            SectionHeader(title: 'Trending Near You', onSeeAll: () {}),
            _buildHorizontalList(MockData.trendingPlaces),
            
            const SizedBox(height: 16),

            // Top Rated
            SectionHeader(title: 'Top Rated Services', onSeeAll: () {}),
            _buildHorizontalList(MockData.topRated),

            const SizedBox(height: 16),

            // Events Prototype
            SectionHeader(title: 'Upcoming Events', onSeeAll: () {}),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.mockEvents.length,
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 280, // constrain width for horizontal scrolling
                      child: EventCard(event: MockData.mockEvents[index]),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Hidden Gems
            SectionHeader(title: 'Hidden Gems', onSeeAll: () {}),
            _buildHorizontalList(MockData.hiddenGems),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/utils/mock_data.dart';
import '../../../../models/place_model.dart';
import '../widgets/ranking_category_chips.dart';
import '../widgets/timeframe_selector.dart';
import '../widgets/ranking_card.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  String _selectedCategory = MockData.rankingCategories.first;
  String _selectedTimeframe = 'This Week';

  List<PlaceModel> _getRankedPlaces() {
    List<PlaceModel> places = List.from(MockData.allPlaces);
    
    if (_selectedCategory == 'Top Rated Doctors') {
      places = places.where((p) => p.category == 'Doctors').toList();
      places.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedCategory == 'Most Reviewed Cafe') {
      places = places.where((p) => p.category == 'Cafes').toList();
      places.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    } else if (_selectedCategory == 'Hidden Gem') {
      places = places.where((p) => p.category == 'Study Places').toList();
      places.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedCategory == 'Family Restaurants') {
      places = places.where((p) => p.category == 'Family Restaurants').toList();
      places.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      // Default sorting
      places.sort((a, b) => b.rating.compareTo(a.rating));
    }
    
    return places;
  }

  @override
  Widget build(BuildContext context) {
    final rankedPlaces = _getRankedPlaces();
    final sponsoredPlaces = rankedPlaces.where((p) => p.isSponsored).toList();
    final organicPlaces = rankedPlaces.where((p) => !p.isSponsored).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Rankings', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          const SizedBox(height: 16),
          TimeframeSelector(
            selectedTimeframe: _selectedTimeframe,
            onTimeframeSelected: (timeframe) {
              setState(() {
                _selectedTimeframe = timeframe;
              });
            },
          ),
          const SizedBox(height: 16),
          RankingCategoryChips(
            categories: MockData.rankingCategories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: rankedPlaces.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No places ranked in this category yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      if (sponsoredPlaces.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                          child: Text(
                            'Sponsored',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        ...sponsoredPlaces.map((place) => RankingCard(
                              place: place,
                              rank: 0,
                              isSponsoredView: true,
                            )),
                        const Divider(height: 32),
                      ],
                      if (organicPlaces.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                          child: Text(
                            'Organic Rankings',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        ...List.generate(
                          organicPlaces.length,
                          (index) => RankingCard(
                            place: organicPlaces[index],
                            rank: index + 1,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

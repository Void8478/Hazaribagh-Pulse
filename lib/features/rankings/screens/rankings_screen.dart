import 'package:flutter/material.dart';

import '../../../../core/utils/mock_data.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../models/place_model.dart';
import '../widgets/ranking_card.dart';
import '../widgets/ranking_category_chips.dart';
import '../widgets/timeframe_selector.dart';

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
      places =
          places.where((p) => p.category == 'Family Restaurants').toList();
      places.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      places.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return places;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = MockData.rankingCategories.first;
      _selectedTimeframe = 'This Week';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rankedPlaces = _getRankedPlaces();
    final sponsoredPlaces = rankedPlaces.where((p) => p.isSponsored).toList();
    final organicPlaces = rankedPlaces.where((p) => !p.isSponsored).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rankings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -1.0,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track the places people trust most across the city.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TimeframeSelector(
                    selectedTimeframe: _selectedTimeframe,
                    onTimeframeSelected: (timeframe) {
                      setState(() {
                        _selectedTimeframe = timeframe;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            RankingCategoryChips(
              categories: MockData.rankingCategories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: rankedPlaces.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: PremiumEmptyState(
                        icon: Icons.emoji_events_outlined,
                        title: 'No rankings yet',
                        subtitle:
                            'Try another category or timeframe to see what is trending around Hazaribagh.',
                        actionLabel: 'Reset Filters',
                        onAction: _resetFilters,
                      ),
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        _RankingsToolbar(
                          totalCount: rankedPlaces.length,
                          selectedCategory: _selectedCategory,
                          selectedTimeframe: _selectedTimeframe,
                          hasFilters:
                              _selectedCategory !=
                                  MockData.rankingCategories.first ||
                              _selectedTimeframe != 'This Week',
                          onClear: _resetFilters,
                        ),
                        if (sponsoredPlaces.isNotEmpty) ...[
                          _RankingsSection(
                            title: 'Sponsored',
                            subtitle:
                                'Featured places with premium placement in this leaderboard.',
                            children: sponsoredPlaces
                                .map(
                                  (place) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: RankingCard(
                                      place: place,
                                      rank: 0,
                                      isSponsoredView: true,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (organicPlaces.isNotEmpty)
                          _RankingsSection(
                            title: 'Organic Rankings',
                            subtitle:
                                'Top performing places based on the selected ranking signal.',
                            children: List.generate(
                              organicPlaces.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: RankingCard(
                                  place: organicPlaces[index],
                                  rank: index + 1,
                                ),
                              ),
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

class _RankingsToolbar extends StatelessWidget {
  const _RankingsToolbar({
    required this.totalCount,
    required this.selectedCategory,
    required this.selectedTimeframe,
    required this.hasFilters,
    required this.onClear,
  });

  final int totalCount;
  final String selectedCategory;
  final String selectedTimeframe;
  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$totalCount ranked places',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (hasFilters)
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToolbarChip(
                icon: Icons.auto_graph_rounded,
                label: selectedTimeframe,
              ),
              _ToolbarChip(
                icon: Icons.workspace_premium_outlined,
                label: selectedCategory,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingsSection extends StatelessWidget {
  const _RankingsSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

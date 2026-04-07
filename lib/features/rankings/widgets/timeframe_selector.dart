import 'package:flutter/material.dart';

class TimeframeSelector extends StatelessWidget {
  final String selectedTimeframe;
  final Function(String) onTimeframeSelected;
  
  const TimeframeSelector({
    super.key,
    required this.selectedTimeframe,
    required this.onTimeframeSelected,
  });

  @override
  Widget build(BuildContext context) {
    const timeframes = ['This Week', 'This Month', 'All Time'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SegmentedButton<String>(
        segments: timeframes.map((tf) => ButtonSegment<String>(
          value: tf,
          label: Text(tf, style: const TextStyle(fontSize: 12)),
        )).toList(),
        selected: {selectedTimeframe},
        onSelectionChanged: (Set<String> newSelection) {
          onTimeframeSelected(newSelection.first);
        },
        style: SegmentedButton.styleFrom(
          selectedForegroundColor: Colors.white,
          selectedBackgroundColor: Theme.of(context).colorScheme.primary,
        ),
        showSelectedIcon: false,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RatingSummaryWidget extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const RatingSummaryWidget({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 4),
        Text(
          rating.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($reviewCount Reviews)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

const FontWeight bold = FontWeight.bold;

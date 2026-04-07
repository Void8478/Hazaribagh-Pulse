import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/place_model.dart';
import '../../listings/widgets/rating_summary_widget.dart';

class RankingCard extends StatelessWidget {
  final PlaceModel place;
  final int rank;
  final bool isSponsoredView;

  const RankingCard({
    super.key,
    required this.place,
    required this.rank,
    this.isSponsoredView = false,
  });

  Color _getBadgeColor(BuildContext context) {
    if (isSponsoredView) return Colors.amber;
    if (rank == 1) return const Color(0xFFD4AF37); // Premium Gold
    if (rank == 2) return const Color(0xFFE2E8F0); // Light Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Theme.of(context).colorScheme.onSurfaceVariant; // Others
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/listing/${place.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isSponsoredView ? Border.all(color: Colors.amber.shade300, width: 2) : null,
          boxShadow: Theme.of(context).brightness == Brightness.light ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rank Badge
              Container(
                width: isSponsoredView ? 30 : 60,
                decoration: BoxDecoration(
                  color: _getBadgeColor(context).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: isSponsoredView 
                    ? RotatedBox(
                        quarterTurns: -1,
                        child: Text(
                          'SPONSORED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      )
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getBadgeColor(context).withAlpha(255),
                        ),
                      ),
                ),
              ),
              
              // Image
              Image.network(
                place.imageUrl,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
              
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.category,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      RatingSummaryWidget(rating: place.rating, reviewCount: place.reviewCount),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

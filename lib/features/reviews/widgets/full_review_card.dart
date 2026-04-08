import 'package:flutter/material.dart';
import 'package:hazaribagh_pulse/models/review_model.dart';

class FullReviewCard extends StatelessWidget {
  final ReviewModel review;

  const FullReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: review.authorImageUrl.isNotEmpty ? NetworkImage(review.authorImageUrl) : null,
                child: review.authorImageUrl.isEmpty 
                    ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant) 
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          '${review.timestamp.year}-${review.timestamp.month.toString().padLeft(2, '0')}-${review.timestamp.day.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.text,
            style: const TextStyle(height: 1.5, fontSize: 15),
          ),
          if (review.pros.isNotEmpty || review.cons.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (review.pros.isNotEmpty)
              _buildProsConsRow(Icons.add_circle, Colors.green, 'Pros:', review.pros),
            if (review.cons.isNotEmpty)
              _buildProsConsRow(Icons.remove_circle, Colors.red, 'Cons:', review.cons),
          ],
          if (review.pricingTip.isNotEmpty || review.bestTimeToVisit.isNotEmpty) ...[
            const Divider(height: 32),
            if (review.pricingTip.isNotEmpty)
              _buildTipRow(Icons.attach_money, 'Tip:', review.pricingTip),
            if (review.bestTimeToVisit.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildTipRow(Icons.access_time, 'Best time:', review.bestTimeToVisit),
            ],
          ],
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.imageUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProsConsRow(IconData icon, Color color, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(content)),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../widgets/star_rating_selector.dart';
import '../providers/review_providers.dart';
import '../../../../models/review_model.dart';
import '../../auth/services/auth_provider.dart';
import '../../bookmarks/providers/bookmark_providers.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String listingId;

  const WriteReviewScreen({super.key, required this.listingId});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 0;
  String _reviewText = '';
  String _pros = '';
  String _cons = '';
  String _pricingTip = '';
  String _bestTimeToVisit = '';
  bool _isSubmitting = false;

  void _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() { _isSubmitting = true; });

      try {
        final fbUser = ref.read(authStateChangesProvider).value;
        if (fbUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to submit a review')));
          setState(() { _isSubmitting = false; });
          return;
        }
        
        final userProfile = ref.read(userProfileProvider).value;

        final newReview = ReviewModel(
          id: const Uuid().v4(), // generate local ID if needed, though Firestore assigns Document ID automatically. We put one to satisfy strict model rules before cloud upload if needed.
          listingId: widget.listingId,
          authorId: fbUser.uid,
          authorName: userProfile?.name ?? 'Anonymous', 
          authorImageUrl: userProfile?.avatarUrl ?? '',
          rating: _rating,
          text: _reviewText,
          timestamp: DateTime.now(),
          pros: _pros,
          cons: _cons,
          pricingTip: _pricingTip,
          bestTimeToVisit: _bestTimeToVisit,
        );

        final repo = ref.read(reviewRepositoryProvider);
        await repo.saveReview(newReview);
        
        // Force refresh the listing reviews so they appear instantly
        ref.invalidate(listingReviewsProvider(widget.listingId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to submit review: $e')),
          );
          setState(() { _isSubmitting = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
        actions: [
          _isSubmitting
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: _submitReview,
                  child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'How would you rate your experience?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              StarRatingSelector(
                initialRating: _rating,
                onRatingChanged: (val) {
                  setState(() { _rating = val; });
                },
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Share your experience'),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'What did you like or dislike?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty ? 'Please write a review' : null,
                onSaved: (value) => _reviewText = value ?? '',
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Pros (Optional)'),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'e.g. Great atmosphere, friendly staff',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSaved: (value) => _pros = value ?? '',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Cons (Optional)'),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'e.g. Hard to find parking',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSaved: (value) => _cons = value ?? '',
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Add Photos'),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image picker would open here.')),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey.shade500, size: 32),
                      const SizedBox(height: 8),
                      Text('Tap to upload photos', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tips
              _buildSectionTitle('Quick Tips (Optional)'),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Pricing Tip',
                  hintText: 'e.g. Try the combo for a better deal',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _pricingTip = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Best time to visit',
                  hintText: 'e.g. Weekday mornings',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _bestTimeToVisit = value ?? '',
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}


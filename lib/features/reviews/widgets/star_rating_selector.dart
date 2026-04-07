import 'package:flutter/material.dart';

class StarRatingSelector extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;

  const StarRatingSelector({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
  });

  @override
  State<StarRatingSelector> createState() => _StarRatingSelectorState();
}

class _StarRatingSelectorState extends State<StarRatingSelector> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          iconSize: 40,
          color: Colors.amber,
          icon: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
          ),
          onPressed: () {
            setState(() {
              _currentRating = index + 1.0;
            });
            widget.onRatingChanged(_currentRating);
          },
        );
      }),
    );
  }
}

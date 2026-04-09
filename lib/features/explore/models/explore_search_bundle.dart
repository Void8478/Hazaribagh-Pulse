import '../../../models/event_model.dart';
import '../../../models/place_model.dart';
import '../../../models/post_model.dart';

class ExploreSearchBundle {
  const ExploreSearchBundle({
    required this.places,
    required this.posts,
    required this.events,
    this.likeCounts = const {},
  });

  final List<PlaceModel> places;
  final List<PostModel> posts;
  final List<EventModel> events;
  final Map<String, int> likeCounts;

  int get totalCount => places.length + posts.length + events.length;

  int likeCountFor(String contentType, String contentId) {
    return likeCounts['$contentType:$contentId'] ?? 0;
  }
}

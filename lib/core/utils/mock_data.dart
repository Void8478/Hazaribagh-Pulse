import 'package:flutter/material.dart';
import '../../models/place_model.dart';
import '../../models/review_model.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';

class MockData {
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Cafes', 'icon': Icons.local_cafe},
    {'name': 'Restaurants', 'icon': Icons.restaurant},
    {'name': 'Doctors', 'icon': Icons.local_hospital},
    {'name': 'Gyms', 'icon': Icons.fitness_center},
    {'name': 'Salons', 'icon': Icons.cut},
    {'name': 'Bookstores', 'icon': Icons.menu_book},
    {'name': 'Coaching Centres', 'icon': Icons.school},
    {'name': 'Tutors', 'icon': Icons.person_search},
    {'name': 'Mechanics', 'icon': Icons.build},
    {'name': 'Study Places', 'icon': Icons.local_library},
    {'name': 'Family Restaurants', 'icon': Icons.family_restroom},
  ];

  static List<ReviewModel> mockReviews = [
    ReviewModel(
      id: 'r1',
      listingId: '1',
      authorId: 'u1',
      authorName: 'Rahul Kumar',
      authorImageUrl: 'https://i.pravatar.cc/150?img=11',
      rating: 5.0,
      text: 'Amazing place! Definitely the best in town. Highly recommended.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      pros: 'Great ambiance\nExcellent food\nFast Wi-fi',
      cons: 'A bit expensive',
      pricingTip: 'Try their combo meals to save money.',
      bestTimeToVisit: 'Evenings',
      imageUrls: [
        'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=500&q=60',
      ],
    ),
    ReviewModel(
      id: 'r2',
      listingId: '3',
      authorId: 'u2',
      authorName: 'Priya Singh',
      authorImageUrl: 'https://i.pravatar.cc/150?img=5',
      rating: 4.0,
      text: 'Good service but can get crowded on weekends. Loved the ambiance.',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      pros: 'Friendly staff\nGood location',
      cons: 'Very crowded on weekends\nHard to find parking',
    ),
  ];

  static const List<PlaceModel> trendingPlaces = [
    PlaceModel(
      id: '1',
      name: 'Cafe Hazaribagh',
      category: 'Cafes',
      imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=500&q=60',
      imageUrls: [
         'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=500&q=60',
         'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=500&q=60',
         'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&w=500&q=60'
      ],
      rating: 4.8,
      reviewCount: 124,
      isSponsored: true,
      isVerified: true,
      address: 'Main Road, Hazaribagh, Jharkhand 825301',
      phone: '+91 98765 43210',
      openingHours: '10:00 AM - 10:00 PM (Everyday)',
      priceRange: '₹₹',
      description: 'The finest cafe in Hazaribagh offering freshly brewed coffee, delicious continental food, and a perfect ambiance to relax or work. Come and enjoy our signature blend!',
    ),
    PlaceModel(
      id: '2',
      name: 'Sharma Sweets',
      category: 'Restaurants',
      imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=500&q=60',
      rating: 4.5,
      reviewCount: 89,
    ),
  ];

  static const List<PlaceModel> topRated = [
    PlaceModel(
      id: '3',
      name: 'City Hospital',
      category: 'Doctors',
      imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=500&q=60',
      rating: 4.9,
      reviewCount: 312,
    ),
    PlaceModel(
      id: '4',
      name: 'Elite Plumbers',
      category: 'Mechanics',
      imageUrl: 'https://images.unsplash.com/photo-1581561512085-c5c8fc5ae86c?auto=format&fit=crop&w=500&q=60',
      rating: 4.7,
      reviewCount: 45,
    ),
  ];

  static const List<PlaceModel> hiddenGems = [
    PlaceModel(
      id: '5',
      name: 'Old Town Library',
      category: 'Study Places',
      imageUrl: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=500&q=60',
      rating: 5.0,
      reviewCount: 12,
    ),
  ];

  static const List<PlaceModel> allPlaces = [
    ...trendingPlaces,
    ...topRated,
    ...hiddenGems,
    PlaceModel(
      id: '6',
      name: 'FitLife Gym',
      category: 'Gyms',
      imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=500&q=60',
      rating: 4.6,
      reviewCount: 67,
    ),
    PlaceModel(
      id: '7',
      name: 'Style Studio Salon',
      category: 'Salons',
      imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=500&q=60',
      rating: 4.4,
      reviewCount: 42,
    ),
    PlaceModel(
      id: '8',
      name: 'Apex Coaching Centre',
      category: 'Coaching Centres',
      imageUrl: 'https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=500&q=60',
      rating: 4.7,
      reviewCount: 115,
    ),
    PlaceModel(
      id: '9',
      name: 'Chapter One Bookstores',
      category: 'Bookstores',
      imageUrl: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=500&q=60',
      rating: 4.9,
      reviewCount: 200,
    ),
    PlaceModel(
      id: '10',
      name: 'Green Leaf Family Restaurant',
      category: 'Family Restaurants',
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=500&q=60',
      rating: 4.3,
      reviewCount: 156,
    ),
  ];

  static const List<String> eventCategories = [
    'All',
    'College Events',
    'Workshops',
    'Food Festivals',
    'Exhibitions',
    'Book Launches',
    'Local Performances',
    'Community Meetups',
  ];

  static List<EventModel> mockEvents = [
    EventModel(
      id: 'e1',
      title: 'VBU Tech Fest 2026',
      category: 'College Events',
      imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=800&q=80',
      organizer: 'Vinoba Bhave University',
      location: 'VBU Main Campus',
      address: 'Sindoor, Hazaribagh',
      date: DateTime.now().add(const Duration(days: 3)),
      time: '10:00 AM - 5:00 PM',
      isFree: true,
      description: 'The biggest regional tech-fest featuring coding competitions, robotics, and guest lectures from industry leaders. Open to all college students in Jharkhand.',
    ),
    EventModel(
      id: 'e2',
      title: 'Digital Marketing Masterclass',
      category: 'Workshops',
      imageUrl: 'https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&w=800&q=80',
      organizer: 'Hazaribagh Creators Hub',
      location: 'Cafe Hazaribagh',
      address: 'Main Road, Hazaribagh',
      date: DateTime.now().add(const Duration(days: 7)),
      time: '2:00 PM - 4:00 PM',
      isFree: false,
      price: '₹499',
      description: 'Learn the secrets of organic growth, Instagram Reels strategy, and personal branding from top local creators. Coffee and snacks included in the ticket.',
    ),
    EventModel(
      id: 'e3',
      title: 'Jharkhand Street Food Fiesta',
      category: 'Food Festivals',
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
      organizer: 'Zomato Local',
      location: 'Curzon Ground',
      address: 'Near District Court, Hazaribagh',
      date: DateTime.now().add(const Duration(days: 12)),
      time: '4:00 PM - 10:00 PM',
      isFree: true,
      description: 'Experience over 50+ stalls serving authentic Jharkhandi delicacies, fusion street food, and incredible desserts. Live music from 6 PM.',
    ),
  ];

  static const List<String> rankingCategories = [
    'Top Rated Doctors',
    'Most Reviewed Cafe',
    'Hidden Gem',
    'Youth Choice Award',
    'Best Study Spot',
    'Family Restaurants',
  ];

  static UserModel currentUser = UserModel(
    id: 'u1',
    fullName: 'Rahul Kumar',
    email: 'rahul.k@example.com',
    phoneNumber: '+91 98765 43210',
    authProvider: 'google',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
    avatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026024d',
    trustLevel: 'Local Expert',
    points: 1250,
    reviewsCount: 14,
    photosCount: 32,
    savedPlaceIds: ['1', '5'],
    savedEventIds: ['e1'],
  );
}

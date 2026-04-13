import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String iconName;
  final String description;
  final int manualRank;
  final int displayOrder;
  final bool isActive;
  final DateTime? createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.iconName = '',
    this.description = '',
    this.manualRank = 0,
    this.displayOrder = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> data) {
    final manualRank =
        int.tryParse((data['manual_rank'] ?? data['display_order'] ?? 0).toString()) ?? 0;

    return CategoryModel(
      id: data['id']?.toString() ?? '',
      name: (data['name'] ?? data['title'] ?? data['label'] ?? 'Category').toString(),
      slug: (data['slug'] ?? '').toString(),
      iconName: (data['icon_name'] ?? data['icon'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      manualRank: manualRank,
      displayOrder:
          int.tryParse((data['display_order'] ?? data['sort_order'] ?? manualRank).toString()) ??
              manualRank,
      isActive: data['is_active'] == null ? true : data['is_active'] == true,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
    );
  }

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'local_cafe':
      case 'cafe':
      case 'cafes':
        return Icons.local_cafe_rounded;
      case 'restaurant':
      case 'restaurants':
        return Icons.restaurant_rounded;
      case 'medical':
      case 'doctor':
      case 'doctors':
      case 'hospital':
      case 'hospitals':
        return Icons.local_hospital_rounded;
      case 'fitness_center':
      case 'gym':
      case 'gyms':
        return Icons.fitness_center_rounded;
      case 'hotel':
      case 'hotels':
      case 'lodging':
        return Icons.hotel_rounded;
      case 'spa':
      case 'salon':
      case 'salons':
        return Icons.spa_rounded;
      case 'tourism':
      case 'travel':
      case 'attractions':
        return Icons.landscape_rounded;
      case 'shopping':
      case 'shop':
      case 'market':
        return Icons.shopping_bag_rounded;
      case 'services':
      case 'service':
      case 'build':
      case 'mechanic':
      case 'mechanics':
        return Icons.handyman_rounded;
      case 'menu_book':
      case 'bookstore':
      case 'bookstores':
        return Icons.menu_book_rounded;
      case 'school':
      case 'study':
      case 'study_places':
        return Icons.school_rounded;
      case 'celebration':
      case 'event':
        return Icons.celebration_rounded;
      default:
        final loweredName = name.toLowerCase();
        if (loweredName.contains('cafe')) return Icons.local_cafe_rounded;
        if (loweredName.contains('restaurant')) return Icons.restaurant_rounded;
        if (loweredName.contains('hospital')) return Icons.local_hospital_rounded;
        if (loweredName.contains('gym')) return Icons.fitness_center_rounded;
        if (loweredName.contains('hotel')) return Icons.hotel_rounded;
        if (loweredName.contains('salon')) return Icons.spa_rounded;
        if (loweredName.contains('tour')) return Icons.landscape_rounded;
        if (loweredName.contains('shop')) return Icons.shopping_bag_rounded;
        if (loweredName.contains('service')) return Icons.handyman_rounded;
        if (loweredName.contains('study')) return Icons.school_rounded;
        if (loweredName.contains('book')) return Icons.menu_book_rounded;
        return Icons.category_rounded;
    }
  }
}

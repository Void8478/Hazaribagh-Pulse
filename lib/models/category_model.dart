import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int displayOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconName = '',
    this.displayOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id']?.toString() ?? '',
      name: (data['name'] ?? data['title'] ?? data['label'] ?? 'Category').toString(),
      iconName: (data['icon_name'] ?? data['icon'] ?? '').toString(),
      displayOrder: int.tryParse((data['display_order'] ?? data['sort_order'] ?? 0).toString()) ?? 0,
    );
  }

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'local_cafe':
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'restaurant':
      case 'restaurants':
        return Icons.restaurant_rounded;
      case 'medical':
      case 'doctor':
      case 'doctors':
        return Icons.local_hospital_rounded;
      case 'fitness_center':
      case 'gym':
      case 'gyms':
        return Icons.fitness_center_rounded;
      case 'menu_book':
      case 'bookstore':
      case 'bookstores':
        return Icons.menu_book_rounded;
      case 'school':
      case 'study':
      case 'study_places':
        return Icons.school_rounded;
      case 'build':
      case 'mechanic':
      case 'mechanics':
        return Icons.build_rounded;
      case 'spa':
      case 'salon':
      case 'salons':
        return Icons.spa_rounded;
      case 'celebration':
      case 'event':
        return Icons.celebration_rounded;
      default:
        final loweredName = name.toLowerCase();
        if (loweredName.contains('cafe')) return Icons.local_cafe_rounded;
        if (loweredName.contains('restaurant')) return Icons.restaurant_rounded;
        if (loweredName.contains('doctor')) return Icons.local_hospital_rounded;
        if (loweredName.contains('gym')) return Icons.fitness_center_rounded;
        if (loweredName.contains('study')) return Icons.school_rounded;
        if (loweredName.contains('book')) return Icons.menu_book_rounded;
        return Icons.category_rounded;
    }
  }
}

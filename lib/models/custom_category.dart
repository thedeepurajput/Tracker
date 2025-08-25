import 'package:flutter/material.dart';

class CustomCategory {
  final String id;
  final String name;
  final String label;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const CustomCategory({
    required this.id,
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
    required this.isExpense,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'iconCode': icon.codePoint.toString(),
      'colorValue': color.value.toString(),
      'isExpense': isExpense.toString(),
    };
  }

  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      icon: IconData(
        int.tryParse(json['iconCode']?.toString() ?? '0') ?? Icons.category.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(int.tryParse(json['colorValue']?.toString() ?? '0') ?? Colors.grey.value),
      isExpense: json['isExpense'] == 'true',
    );
  }
}

// Predefined icons for user selection
class CategoryIcons {
  static const List<IconData> expenseIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_gas_station,
    Icons.movie,
    Icons.fitness_center,
    Icons.medical_services,
    Icons.school,
    Icons.home,
    Icons.pets,
    Icons.flight,
    Icons.phone,
    Icons.wifi,
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.local_laundry_service,
    Icons.cut,
    Icons.spa,
    Icons.sports_esports,
    Icons.library_books,
    Icons.music_note,
  ];

  static const List<IconData> incomeIcons = [
    Icons.work,
    Icons.business_center,
    Icons.laptop_mac,
    Icons.trending_up,
    Icons.account_balance,
    Icons.card_giftcard,
    Icons.monetization_on,
    Icons.savings,
    Icons.real_estate_agent,
    Icons.store,
    Icons.agriculture,
    Icons.construction,
    Icons.design_services,
    Icons.local_shipping,
    Icons.restaurant_menu,
    Icons.camera_alt,
    Icons.brush,
    Icons.code,
    Icons.healing,
    Icons.gavel,
  ];

  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFFFFE66D), // Yellow
    Color(0xFF6C63FF), // Purple
    Color(0xFF00B894), // Green
    Color(0xFFFF9F43), // Orange
    Color(0xFF74B9FF), // Blue
    Color(0xFFE84393), // Pink
    Color(0xFF00CEC9), // Cyan
    Color(0xFFFD79A8), // Light Pink
    Color(0xFFE17055), // Orange Red
    Color(0xFF81ECEC), // Light Teal
    Color(0xFFFDCB6E), // Light Orange
    Color(0xFF6C5CE7), // Light Purple
    Color(0xFFA29BFE), // Lavender
    Color(0xFFFF7675), // Light Red
    Color(0xFF55A3FF), // Sky Blue
    Color(0xFF26DE81), // Light Green
    Color(0xFFFD79A8), // Rose
    Color(0xFF2D3436), // Dark Gray
  ];
}

import 'package:flutter/material.dart';

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final bool isRecurring;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    required this.isRecurring,
  });

  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;
  double get displayAmount => amount.abs();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.toString().split('.').last,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod.toString().split('.').last,
      'isRecurring': isRecurring ? 1 : 0,
    };
  }
}

enum ExpenseCategory {
  food, transport, shopping, entertainment, bills, health, education, groceries, fuel, other;

  String get label => name[0].toUpperCase() + name.substring(1);

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food: return Icons.restaurant;
      case ExpenseCategory.transport: return Icons.directions_car;
      case ExpenseCategory.shopping: return Icons.shopping_bag;
      case ExpenseCategory.entertainment: return Icons.movie;
      case ExpenseCategory.bills: return Icons.receipt;
      case ExpenseCategory.health: return Icons.local_hospital;
      case ExpenseCategory.education: return Icons.school;
      case ExpenseCategory.groceries: return Icons.local_grocery_store;
      case ExpenseCategory.fuel: return Icons.local_gas_station;
      case ExpenseCategory.other: return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food: return const Color(0xFFFF6B6B);
      case ExpenseCategory.transport: return const Color(0xFF4ECDC4);
      case ExpenseCategory.shopping: return const Color(0xFFFFE66D);
      case ExpenseCategory.entertainment: return const Color(0xFF1A535C);
      case ExpenseCategory.bills: return const Color(0xFF6B5B95);
      case ExpenseCategory.health: return const Color(0xFF88D8B0);
      case ExpenseCategory.education: return const Color(0xFFB56576);
      case ExpenseCategory.groceries: return const Color(0xFF6A994E);
      case ExpenseCategory.fuel: return const Color(0xFFFF9F1C);
      case ExpenseCategory.other: return const Color(0xFFB0BEC5);
    }
  }
}

enum PaymentMethod {
  cash, creditCard, debitCard, upi, other;

  String get label {
    switch (this) {
      case PaymentMethod.creditCard: return 'Credit Card';
      case PaymentMethod.debitCard: return 'Debit Card';
      case PaymentMethod.upi: return 'UPI';
      default: return name[0].toUpperCase() + name.substring(1);
    }
  }
}
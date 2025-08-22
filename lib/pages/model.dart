import 'package:flutter/material.dart';

class ExpenseItem {
  final String id;
  final String title;
  final String description;
  final double amount; // Positive for expenses, negative for income
  final ExpenseCategory category;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final bool isRecurring;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    required this.isRecurring,
  });

  bool get isIncome => amount < 0;
  bool get isExpense => amount > 0;
  double get displayAmount => amount.abs();

  ExpenseItem copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    PaymentMethod? paymentMethod,
    bool? isRecurring,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod.name,
      'isRecurring': isRecurring,
    };
  }

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
            (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date'] as String),
      paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      isRecurring: json['isRecurring'] as bool? ?? false,
    );
  }
}

enum ExpenseCategory {
  food,
  transport,
  shopping,
  entertainment,
  bills,
  health,
  education,
  groceries,
  fuel,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transport:
        return 'Transportation';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.bills:
        return 'Bills & Utilities';
      case ExpenseCategory.health:
        return 'Health & Fitness';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.groceries:
        return 'Groceries';
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_outlined;
      case ExpenseCategory.transport:
        return Icons.directions_car_outlined;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.entertainment:
        return Icons.movie_outlined;
      case ExpenseCategory.bills:
        return Icons.receipt_long_outlined;
      case ExpenseCategory.health:
        return Icons.health_and_safety_outlined;
      case ExpenseCategory.education:
        return Icons.school_outlined;
      case ExpenseCategory.groceries:
        return Icons.local_grocery_store_outlined;
      case ExpenseCategory.fuel:
        return Icons.local_gas_station_outlined;
      case ExpenseCategory.other:
        return Icons.category_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF6B6B);
      case ExpenseCategory.transport:
        return const Color(0xFF4ECDC4);
      case ExpenseCategory.shopping:
        return const Color(0xFFFFE66D);
      case ExpenseCategory.entertainment:
        return const Color(0xFF1A535C);
      case ExpenseCategory.bills:
        return const Color(0xFF6B5B95);
      case ExpenseCategory.health:
        return const Color(0xFF88D8B0);
      case ExpenseCategory.education:
        return const Color(0xFFB56576);
      case ExpenseCategory.groceries:
        return const Color(0xFF6A994E);
      case ExpenseCategory.fuel:
        return const Color(0xFFFF9F1C);
      case ExpenseCategory.other:
        return const Color(0xFFB0BEC5);
    }
  }
}

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  upi,
  wallet,
  other,
  netBanking;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.other:
        return 'Other';
      case PaymentMethod.netBanking:
        return 'Net Banking';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case PaymentMethod.upi:
        return Icons.qr_code;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.other:
        return Icons.payment;
      case PaymentMethod.netBanking:
        return Icons.account_balance;
    }
  }
}


enum IncomeCategory {
  salary,
  business,
  freelance,
  investment,
  bonus,
  gift,
  other;

  String get label {
    switch (this) {
      case IncomeCategory.salary:
        return 'Salary';
      case IncomeCategory.business:
        return 'Business';
      case IncomeCategory.freelance:
        return 'Freelance';
      case IncomeCategory.investment:
        return 'Investment';
      case IncomeCategory.bonus:
        return 'Bonus';
      case IncomeCategory.gift:
        return 'Gift';
      case IncomeCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case IncomeCategory.salary:
        return Icons.work_outline;
      case IncomeCategory.business:
        return Icons.business_center_outlined;
      case IncomeCategory.freelance:
        return Icons.laptop_mac_outlined;
      case IncomeCategory.investment:
        return Icons.trending_up_outlined;
      case IncomeCategory.bonus:
        return Icons.card_giftcard_outlined;
      case IncomeCategory.gift:
        return Icons.redeem_outlined;
      case IncomeCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case IncomeCategory.salary:
        return const Color(0xFF00B894);
      case IncomeCategory.business:
        return const Color(0xFF0984E3);
      case IncomeCategory.freelance:
        return const Color(0xFF6C5CE7);
      case IncomeCategory.investment:
        return const Color(0xFFE17055);
      case IncomeCategory.bonus:
        return const Color(0xFFFFE66D);
      case IncomeCategory.gift:
        return const Color(0xFFFF7675);
      case IncomeCategory.other:
        return const Color(0xFF636E72);
    }
  }
}

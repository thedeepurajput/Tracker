import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoryPreferences {
  static const String _deletedExpenseKey = 'deleted_expense_categories';
  static const String _deletedIncomeKey = 'deleted_income_categories';
  static const String _customExpenseKey = 'custom_expense_categories';
  static const String _customIncomeKey = 'custom_income_categories';

  // Save deleted categories
  static Future<void> saveDeletedExpenseCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_deletedExpenseKey, categories);
  }

  static Future<void> saveDeletedIncomeCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_deletedIncomeKey, categories);
  }

  // Get deleted categories
  static Future<List<String>> getDeletedExpenseCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_deletedExpenseKey) ?? [];
  }

  static Future<List<String>> getDeletedIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_deletedIncomeKey) ?? [];
  }

  // Save custom categories
  static Future<void> saveCustomExpenseCategories(List<Map<String, dynamic>> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(categories);
    await prefs.setString(_customExpenseKey, jsonString);
  }

  static Future<void> saveCustomIncomeCategories(List<Map<String, dynamic>> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(categories);
    await prefs.setString(_customIncomeKey, jsonString);
  }

  // Get custom categories
  static Future<List<Map<String, dynamic>>> getCustomExpenseCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customExpenseKey);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getCustomIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customIncomeKey);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }

  // Clear all preferences (for testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deletedExpenseKey);
    await prefs.remove(_deletedIncomeKey);
    await prefs.remove(_customExpenseKey);
    await prefs.remove(_customIncomeKey);
  }
}

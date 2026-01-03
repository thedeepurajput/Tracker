import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Theme Notifier (New) ---
  // Default System rakhenge
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  // --- Colors ---
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00B894);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF1A1D1E);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFE0E0E0);

  // --- Download Dialog Theme ---
  static ThemeData get downloadDialogTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF2D3748),
        secondary: Color(0xFFFFA726),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: primary,
        headerForegroundColor: Colors.white,
        dayStyle: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
        todayBackgroundColor: MaterialStateProperty.all(const Color(0xFFFFA726).withOpacity(0.2)),
        todayForegroundColor: MaterialStateProperty.all(const Color(0xFFFFA726)),
      ),
    );
  }

  // --- Light Theme ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
        background: lightBackground,
        onBackground: lightText,
        onSurface: lightText,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightText),
        titleTextStyle: TextStyle(color: lightText, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- Dark Theme ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: darkSurface,
        background: darkBackground,
        onBackground: darkText,
        onSurface: darkText,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
    );
  }
}
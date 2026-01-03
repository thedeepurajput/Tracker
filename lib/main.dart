import 'package:expanse_tracker/services/pre_Homepage.dart';
import 'package:expanse_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation Lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Load Saved Theme
  final prefs = await SharedPreferences.getInstance();
  final themeString = prefs.getString('theme_mode');

  // Set initial theme
  if (themeString == 'light') {
    AppTheme.themeNotifier.value = ThemeMode.light;
  } else if (themeString == 'dark') {
    AppTheme.themeNotifier.value = ThemeMode.dark;
  } else {
    AppTheme.themeNotifier.value = ThemeMode.system;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const PreHomePage(),
        );
      },
    );
  }
}
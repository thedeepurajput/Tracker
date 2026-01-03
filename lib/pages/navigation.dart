import 'package:flutter/material.dart';
import './home_page.dart';
import './Profile.DART';
import './stats_page.dart'; // Import New Page
import '../theme/app_theme.dart'; // Import for theme colors

class Navigation extends StatefulWidget {
  final String userName;

  const Navigation({super.key, required this.userName});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _currentIndex = 0;
  int _homePageKey = 0; // Key to force refresh

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages
    _pages = [
      HomePage(key: ValueKey(_homePageKey), userName: widget.userName, title: ''),
      const StatsPage(), // Middle Page
      const Profile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Re-create Home with key to allow refreshing
          HomePage(key: ValueKey(_homePageKey), userName: widget.userName, title: ''),
          const StatsPage(),
          const Profile(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: theme.colorScheme.primary.withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.all(
              TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color)
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            final oldIndex = _currentIndex;
            setState(() => _currentIndex = index);

            // Refresh home if returning to it
            if (index == 0 && oldIndex != 0) {
              setState(() => _homePageKey++);
            }
          },
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
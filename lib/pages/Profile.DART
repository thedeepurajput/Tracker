import 'dart:io'; // File handling ke liye
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart'; // Photo pick karne ke liye
import 'package:path_provider/path_provider.dart'; // Save karne ke liye
import 'package:path/path.dart' as path;
import '../services/DatabaseHelper.dart';
import '../theme/app_theme.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String userName = 'User';
  String appVersion = '';
  String? _profileImagePath; // Path to store image
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    setState(() {
      userName = prefs.getString('user_name') ?? 'User';
      _profileImagePath = prefs.getString('user_profile_image'); // Load Image Path
      appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  // --- NEW: Image Picker & Save Logic ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // 1. Pick Image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // 2. Get App Directory (Offline Storage)
    final Directory appDir = await getApplicationDocumentsDirectory();

    // 3. Create a unique file name
    final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File localImage = await File(image.path).copy('${appDir.path}/$fileName');

    // 4. Save Path to Preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_image', localImage.path);

    // 5. Update UI
    setState(() {
      _profileImagePath = localImage.path;
    });
  }

  Future<void> _editUsername() async {
    _nameController.text = userName;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, _nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', result);
      await ExpenseDatabase.instance.setUserName('user_1', result);
      setState(() => userName = result);
    }
  }

  void _toggleTheme() async {
    final currentMode = AppTheme.themeNotifier.value;
    ThemeMode newMode;
    String message;

    if (currentMode == ThemeMode.system) {
      newMode = ThemeMode.light;
      message = "Light Mode Enabled";
    } else if (currentMode == ThemeMode.light) {
      newMode = ThemeMode.dark;
      message = "Dark Mode Enabled";
    } else {
      newMode = ThemeMode.system;
      message = "System Theme Enabled";
    }

    AppTheme.themeNotifier.value = newMode;

    final prefs = await SharedPreferences.getInstance();
    String modeString = 'system';
    if (newMode == ThemeMode.light) modeString = 'light';
    if (newMode == ThemeMode.dark) modeString = 'dark';
    await prefs.setString('theme_mode', modeString);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          width: 200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
    );
  }

  Future<void> _resetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text('Are you sure you want to delete ALL transactions? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await ExpenseDatabase.instance.database;
      await db.delete('transactions');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data has been reset')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(theme, isDark),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text("Preferences", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),

                  _buildSectionContainer(theme, [
                    _buildSettingsTile(
                      theme,
                      icon: Icons.person_outline_rounded,
                      title: "Display Name",
                      subtitle: userName,
                      onTap: _editUsername,
                      trailing: Icon(Icons.edit_rounded, size: 18, color: Colors.grey[400]),
                    ),
                    _buildDivider(theme),

                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: AppTheme.themeNotifier,
                      builder: (context, mode, _) {
                        return _buildSettingsTile(
                          theme,
                          icon: _getThemeIcon(mode),
                          title: "Appearance",
                          subtitle: _getThemeName(mode),
                          onTap: _toggleTheme,
                          trailing: Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: mode == ThemeMode.dark,
                              onChanged: (val) => _toggleTheme(),
                              activeColor: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 25),
                  Text("Danger Zone", style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),

                  _buildSectionContainer(theme, [
                    _buildSettingsTile(
                      theme,
                      icon: Icons.delete_forever_rounded,
                      title: "Reset All Data",
                      subtitle: "Clear all transaction history",
                      isDestructive: true,
                      onTap: _resetData,
                    ),
                  ]),

                  const SizedBox(height: 40),

                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          "Expense Tracker v$appVersion",
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 280,
          margin: const EdgeInsets.only(bottom: 50),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                  : [theme.colorScheme.primary, const Color(0xFF4B6EFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
        ),

        Positioned(
          bottom: 0,
          child: Stack(
            children: [
              // Profile Circle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  // Check if image exists
                  backgroundImage: _profileImagePath != null
                      ? FileImage(File(_profileImagePath!))
                      : null,
                  child: _profileImagePath == null
                      ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  )
                      : null,
                ),
              ),

              // Edit Button (Camera Icon)
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: _pickImage, // Tap to change photo
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                  ),
                ),
              )
            ],
          ),
        ),

        Positioned(
          top: 60,
          left: 20,
          child: Text(
            "Profile",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContainer(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
      ThemeData theme, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        Widget? trailing,
        bool isDestructive = false,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : theme.colorScheme.primary,
                    size: 22
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDestructive ? Colors.red : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing
              else Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
        height: 1,
        thickness: 1,
        color: theme.dividerColor.withOpacity(0.05),
        indent: 20,
        endIndent: 20
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System Default';
      case ThemeMode.light: return 'Light Mode';
      case ThemeMode.dark: return 'Dark Mode';
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return Icons.brightness_auto_rounded;
      case ThemeMode.light: return Icons.wb_sunny_rounded;
      case ThemeMode.dark: return Icons.nightlight_round;
    }
  }
}
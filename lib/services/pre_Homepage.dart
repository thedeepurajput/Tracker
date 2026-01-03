import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart'; // Add this package
import '../pages/navigation.dart';

class PreHomePage extends StatefulWidget {
  const PreHomePage({super.key});
  @override
  State<PreHomePage> createState() => _PreHomePageState();
}

class _PreHomePageState extends State<PreHomePage> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkStatus();
  }

  void _initAnimations() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeInAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
  }

  Future<void> _checkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('user_name');

    if (name != null && name.isNotEmpty) {
      // User exists, try biometric auth
      bool authenticated = false;
      try {
        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        if (canAuthenticateWithBiometrics) {
          authenticated = await auth.authenticate(
            localizedReason: 'Authenticate to access your expenses',
            options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
          );
        } else {
          authenticated = true; // Skip if no hardware
        }
      } catch (e) {
        authenticated = true; // Fallback on error
      }

      if (authenticated) {
        _goToHome(name);
      } else {
        // Auth failed, maybe exit or show button to retry
        setState(() => _isLoading = false);
      }
    } else {
      // New User
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  void _saveNameAndProceed() async {
    String name = _nameController.text.trim();
    if (name.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    _goToHome(name);
  }

  void _goToHome(String name) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Navigation(userName: name)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // ... (UI code remains mostly same, keeping it concise here)
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primary.withOpacity(0.8), theme.colorScheme.surface], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.security, size: 60, color: Color(0xFF6C63FF)),
                      const SizedBox(height: 16),
                      Text("Welcome", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Enter your name",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(width: double.infinity, child: FilledButton(onPressed: _saveNameAndProceed, child: const Text("Get Started"))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
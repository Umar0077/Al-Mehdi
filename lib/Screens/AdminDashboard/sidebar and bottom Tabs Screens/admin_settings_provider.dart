import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../main.dart';
import '../../Auth Screens/login_screen.dart';
import '../../../services/session_helper.dart';
import '../../../services/theme_service.dart';
import '../../../constants/colors.dart';

class AdminSettingsProvider extends ChangeNotifier {
  bool notificationsEnabled = true;
  String selectedLanguage = 'English';
  bool _isLoading = false;

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;
  bool get isLoading => _isLoading;

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void setDarkMode(bool value) async {
    final newTheme = value ? ThemeMode.dark : ThemeMode.light;
    themeNotifier.value = newTheme;
    
    // Save theme preference
    try {
      await ThemeService.instance.saveTheme(newTheme);
      print('✅ Theme saved: $newTheme');
    } catch (e) {
      print('⚠️ Failed to save theme: $e');
    }
    
    notifyListeners();
  }

  void setSelectedLanguage(String lang) {
    selectedLanguage = lang;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Show logout confirmation dialog
  Future<void> showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold),)),
        content: const Text('Are you sure you want to logout?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: appGreen),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await performLogout(context);
            },
            child: const Text(
              'Logout',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: appGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Perform logout
  Future<void> performLogout(BuildContext context) async {
    try {
      _setLoading(true);

      // Clear admin session completely
      await clearAdminSession();

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      _setLoading(false);

      // Navigate to login screen and clear the navigation stack
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _setLoading(false);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

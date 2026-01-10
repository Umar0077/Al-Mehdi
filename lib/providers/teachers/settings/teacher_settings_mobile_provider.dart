import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../services/theme_service.dart';
import '../../../views/authentication/login_view.dart';

class TeacherSettingsMobileProvider extends ChangeNotifier {
  bool notificationsEnabled = true;
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Show logout confirmation dialog
  Future<void> showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Center(
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: const Text('Are you sure you want to logout?'),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context); // Close dialog first
                  await performLogout(context);
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  // Perform logout
  Future<void> performLogout(BuildContext context) async {
    try {
      _setLoading(true);

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      _setLoading(false);

      // Navigate to login screen and clear the navigation stack
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
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

  // Show delete account confirmation dialog
  Future<void> showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Center(
              child: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context); // Close dialog first
                  await deleteAccount(context);
                },
                child: const Text(
                  'Yes, Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  // Delete account
  Future<void> deleteAccount(BuildContext context) async {
    try {
      _setLoading(true);

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userId = user.uid;
        final batch = FirebaseFirestore.instance.batch();

        // Delete user's main document from Firestore
        final userRef = FirebaseFirestore.instance
            .collection('teachers')
            .doc(userId);

        // Delete all subcollections
        final subcollections = [
          'messages',
          'classes',
          'assignments',
          'students',
        ];

        for (String subcollection in subcollections) {
          final subcollectionRef = userRef.collection(subcollection);
          final snapshot = await subcollectionRef.get();

          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
        }

        // Delete the user's main document
        batch.delete(userRef);

        // Commit the batch operation
        await batch.commit();

        // Delete user from Firebase Authentication
        await user.delete();

        _setLoading(false);

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to the Login screen after account deletion
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      _setLoading(false);

      // Handle specific Firebase errors
      String errorMessage = 'An error occurred while deleting the account.';

      if (e.toString().contains('requires-recent-login')) {
        errorMessage =
            'Please log in again before deleting your account for security reasons.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }
}

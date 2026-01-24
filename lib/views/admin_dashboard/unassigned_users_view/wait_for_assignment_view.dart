import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:al_mehdi_online_school/providers/auth/auth_provider.dart';
import 'package:al_mehdi_online_school/views/authentication/login_view.dart';
import 'package:flutter/material.dart';

class WaitForAssignmentView extends StatelessWidget {
  final String role; // 'Student' or 'Teacher'
  final Map<String, dynamic>? registrationData;

  const WaitForAssignmentView({
    super.key,
    required this.role,
    this.registrationData,
  });

  Future<void> _signOutAndGoToLogin(BuildContext context) async {
    // Create a new AuthProvider instance for sign-out
    final authProvider = AuthProvider();
    await authProvider.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false, // Remove all routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: const Text('Awaiting Assignment'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_bottom,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Almost there!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account will be activated once you are assigned by the admin.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait for the admin to assign you to a ${role == 'Teacher' ? 'student' : 'teacher'}.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Interactive sign out button
                OutlinedButton.icon(
                  onPressed: () => _signOutAndGoToLogin(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appRed,
                    side: const BorderSide(color: appRed),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can sign back in once you\'ve been assigned',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

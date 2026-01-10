import 'package:al_mehdi_online_school/views/auth_views/login_screen.dart';
import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../views/auth_views/change password.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreferenceCard extends StatelessWidget {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String selectedLanguage;
  final ValueChanged<bool> onNotificationChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onLanguageChanged;

  const PreferenceCard({
    super.key,
    required this.notificationsEnabled,
    required this.darkModeEnabled,
    required this.selectedLanguage,
    required this.onNotificationChanged,
    required this.onDarkModeChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).shadowColor,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildCheckboxRow(
              Icons.notifications,
              "Notifications",
              notificationsEnabled,
              onNotificationChanged,
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.nightlight_round, color: appGreen),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text("Dark Mode", style: TextStyle(fontSize: 16)),
                ),
                Switch(
                  value: darkModeEnabled,
                  onChanged: onDarkModeChanged,
                  activeThumbColor: appGreen,
                  inactiveThumbColor: appGreen,
                  inactiveTrackColor: Theme.of(context).scaffoldBackgroundColor,
                  trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return appGreen;
                    }
                    return appGreen; // Use the default color.
                  }),
                ),
              ],
            ),
            const Divider(),
            // Language option removed as requested
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: appGreen),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Checkbox(
          value: value,
          onChanged: (val) => onChanged(val!),
          activeColor: appGreen,
          side: const BorderSide(color: appGreen),
        ),
      ],
    );
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Theme.of(context).shadowColor,
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChangePassword()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text("Change Password"),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appRed,
                  foregroundColor: Colors.white,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text("Logout"),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "Delete Account",
                  style: TextStyle(color: appRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

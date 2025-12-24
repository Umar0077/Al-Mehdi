import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class TeacherPreferenceCard extends StatelessWidget {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final ValueChanged<bool> onNotificationChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const TeacherPreferenceCard({
    super.key,
    required this.notificationsEnabled,
    required this.darkModeEnabled,
    required this.onNotificationChanged,
    required this.onDarkModeChanged,
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
                  activeColor: appGreen,
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
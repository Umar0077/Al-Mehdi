import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/colors.dart';
import '../../../providers/admin/admin_settings_provider.dart';
import '../../../providers/unassigned_user/notifications_provider.dart';
import '../notifications_view.dart';

class AdminSettingsViewWeb extends StatelessWidget {
  const AdminSettingsViewWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminSettingsProvider>(
      create: (_) => AdminSettingsProvider(),
      child: Consumer<AdminSettingsProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Settings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            ChangeNotifierProvider<NotificationsProvider>(
                              create:
                                  (_) => NotificationsProvider()..initialize(),
                              child: Consumer<NotificationsProvider>(
                                builder: (context, notifProvider, _) {
                                  return AdminNotificationIcon(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => NotificationView(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPreferenceCard(context, provider),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAccountCard(context, provider),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreferenceCard(
    BuildContext context,
    AdminSettingsProvider provider,
  ) {
    final isDarkMode = provider.isDarkMode;
    // dropdownColor removed as language option has been removed
    return Card(
      color: Theme.of(context).cardColor,
      shadowColor: Theme.of(context).shadowColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildCheckboxRow(
              Icons.notifications,
              "Notifications",
              provider.notificationsEnabled,
              (val) => provider.setNotificationsEnabled(val!),
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
                  value: isDarkMode,
                  onChanged: provider.setDarkMode,
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

  Widget _buildAccountCard(
    BuildContext context,
    AdminSettingsProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Theme.of(context).cardColor,
        shadowColor: Theme.of(context).shadowColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: appGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Account Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          provider.isLoading
                              ? null
                              : () => provider.showLogoutConfirmationDialog(
                                context,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            provider.isLoading
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Logout",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: appGreen),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: appGreen,
          side: BorderSide(color: appGreen),
        ),
      ],
    );
  }
}

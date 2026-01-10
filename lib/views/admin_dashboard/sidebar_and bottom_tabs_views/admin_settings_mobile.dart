import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/colors.dart';
import '../../../providers/admin/admin_settings_provider.dart';

class AdminSettingsViewMobile extends StatelessWidget {
  const AdminSettingsViewMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminSettingsProvider>(
      create: (_) => AdminSettingsProvider(),
      child: Consumer<AdminSettingsProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              elevation: 0,
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPreferenceCard(context, provider),
                  const SizedBox(height: 24),
                  _buildAccountCard(context, provider),
                ],
              ),
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
                  value: provider.isDarkMode,
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
                    return appGreen;
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    provider.isLoading
                        ? null
                        : () => provider.showLogoutConfirmationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(8.0),
                ),
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
                            const Text(
                              "Logout",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
              ),
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
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: appGreen),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: appGreen,
          side: const BorderSide(color: appGreen),
        ),
      ],
    );
  }
}

import 'package:al_mehdi_online_school/services/notification_service.dart';
import 'package:al_mehdi_online_school/views/authentication/forgot_password_view.dart';
import 'package:al_mehdi_online_school/views/support/support_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/colors.dart';
import '../../../providers/teachers/teacher_settings_web_provider.dart';
import '../../students/student_notifications/student_notifications.dart';

class TeacherSettingsScreenWeb extends StatelessWidget {
  const TeacherSettingsScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherSettingsWebProvider>(
      create: (_) => TeacherSettingsWebProvider(),
      child: Consumer<TeacherSettingsWebProvider>(
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
                            // Support Button
                            IconButton(
                              icon: const Icon(Icons.support_agent),
                              tooltip: 'Support & Help',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SupportView(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  NotificationService.getNotificationsStream(),
                              builder: (context, snapshot) {
                                int unreadCount = 0;
                                if (snapshot.hasData) {
                                  unreadCount =
                                      snapshot.data!.docs
                                          .where(
                                            (doc) => !(doc['read'] ?? false),
                                          )
                                          .length;
                                }
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    StudentNotificationScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
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
    TeacherSettingsWebProvider provider,
  ) {
    final isDarkMode = provider.isDarkMode;
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
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
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    TeacherSettingsWebProvider provider,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordView(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_reset_outlined, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Reset Password",
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
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
                                      Flexible(
                                        child: Text(
                                          "Logout",
                                          style: TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed:
                            provider.isLoading
                                ? null
                                : () => provider.showDeleteConfirmationDialog(
                                  context,
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
                                        Colors.red,
                                      ),
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_forever,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          "Delete Account",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
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

import 'package:al_mehdi_online_school/views/auth_views/forgot_password.dart';
import 'package:al_mehdi_online_school/views/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teacher_settings_mobile_provider.dart';
import '../../../constants/colors.dart';
import '../../students/student_settings/widgets.dart';
import 'teacher_preference_card.dart';

class TeacherSettingsScreenMobile extends StatelessWidget {
  const TeacherSettingsScreenMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherSettingsMobileProvider>(
      create: (_) => TeacherSettingsMobileProvider(),
      child: Consumer<TeacherSettingsMobileProvider>(builder: (context, provider, _) {
        final isDarkMode = provider.isDarkMode;
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
                TeacherPreferenceCard(
                  notificationsEnabled: provider.notificationsEnabled,
                  darkModeEnabled: isDarkMode,
                  onNotificationChanged: provider.setNotificationsEnabled,
                  onDarkModeChanged: provider.setDarkMode,
                ),
                const SizedBox(height: 24),
                // Account Settings Card
                Card(
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
                            Icon(
                              Icons.account_circle,
                              color: appGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Account Settings',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPassword(
                                        isFromSettings: true,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_reset_outlined, size: 16),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Reset Password",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: provider.isLoading
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
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () => provider.showDeleteConfirmationDialog(context),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.delete_forever, size: 16, color: Colors.red),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Delete Account",
                                            style: TextStyle(fontSize: 14, color: Colors.red),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Need help? ',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: 'Tap here for support ',
                            style: TextStyle(
                              color: appGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          WidgetSpan(
                            child: Icon(
                              Icons.support_agent,
                              size: 16,
                              color: appGrey,
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
        );
      }),
    );
  }
}

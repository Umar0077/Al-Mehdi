import 'package:al_mehdi_online_school/Screens/Auth%20Screens/forgot_password.dart';
import 'package:al_mehdi_online_school/Screens/support_screen.dart';
import 'package:al_mehdi_online_school/students/student_settings/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/colors.dart';
import 'student_settings_web_provider.dart';
import 'package:al_mehdi_online_school/services/notification_service.dart';
import 'package:al_mehdi_online_school/students/student_notifications/student_notifications.dart';

class StudentSettingsWebView extends StatelessWidget {
  const StudentSettingsWebView({super.key});

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: appGrey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => launchUrl(Uri.parse('https://abbasonline.com/almehdipayment')),
                  child: Text(
                    'https://abbasonline.com/almehdipayment',
                    style: TextStyle(
                      color: appGreen,
                      decoration: TextDecoration.underline,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Open this Link to pay fee',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentSettingsWebProvider>(
      create: (_) => StudentSettingsWebProvider(),
      child: Consumer<StudentSettingsWebProvider>(builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preferences Section
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: PreferenceCard(
                          notificationsEnabled: provider.notificationsEnabled,
                          darkModeEnabled: provider.isDarkMode,
                          selectedLanguage: provider.selectedLanguage,
                          onNotificationChanged: provider.setNotificationsEnabled,
                          onDarkModeChanged: provider.setDarkMode,
                          onLanguageChanged: provider.setLanguage,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // AccountCard with Delete Account button inside
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Account Settings Card
                            SizedBox(
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
                                                    builder: (context) => const ForgotPassword(),
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
                            ),
                            const SizedBox(height: 24),
                            // Payment Settings Card
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                color: Theme.of(context).cardColor,
                                shadowColor: Theme.of(context).shadowColor,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.payment,
                                            color: appGreen,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Payment',
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Manage your payment information and settings.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _showPaymentDialog(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: appGreen,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.payment, size: 20),
                                              const SizedBox(width: 8),
                                              const Text(
                                                "Go to Payment Page",
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
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
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      child: Row(
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                  builder: (context) => const SupportScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          StreamBuilder<QuerySnapshot>(
            stream: NotificationService.getNotificationsStream(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.where((doc) => !(doc['read'] ?? false)).length;
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentNotificationScreen(),
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
    );
  }
}

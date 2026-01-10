import 'package:al_mehdi_online_school/views/authentication/forgot_password_view.dart';
import 'package:al_mehdi_online_school/views/support/support_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../constants/colors.dart';
import '../../../providers/students/settings/student_settings_mobile_provider.dart';
import 'widgets.dart';

class StudentSettingsMobileView extends StatelessWidget {
  const StudentSettingsMobileView({super.key});

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap:
                    () => launchUrl(
                      Uri.parse('https://abbasonline.com/almehdipayment'),
                    ),
                child: Text(
                  'https://abbasonline.com/almehdipayment',
                  style: TextStyle(
                    color: appGreen,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Open this Link to pay fee'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: appGreen)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentSettingsMobileProvider>(
      create: (_) => StudentSettingsMobileProvider(),
      child: Consumer<StudentSettingsMobileProvider>(
        builder: (context, provider, _) {
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
                  PreferenceCard(
                    notificationsEnabled: provider.notificationsEnabled,
                    darkModeEnabled: isDarkMode,
                    selectedLanguage: provider.selectedLanguage,
                    onNotificationChanged: provider.setNotificationsEnabled,
                    onDarkModeChanged: provider.setDarkMode,
                    onLanguageChanged: provider.setLanguage,
                  ),
                  const SizedBox(height: 24),
                  // Account Settings Card
                  Card(
                    color: Theme.of(context).cardColor,
                    shadowColor: Theme.of(context).shadowColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                        builder:
                                            (context) =>
                                                const ForgotPasswordView(
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
                                  onPressed:
                                      provider.isLoading
                                          ? null
                                          : () => provider
                                              .showLogoutConfirmationDialog(
                                                context,
                                              ),
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                  onPressed:
                                      provider.isLoading
                                          ? null
                                          : () => provider
                                              .showDeleteConfirmationDialog(
                                                context,
                                              ),
                                  child:
                                      provider.isLoading
                                          ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.red,
                                                  ),
                                            ),
                                          )
                                          : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.delete_forever,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                "Delete Account",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red,
                                                ),
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
                            builder: (context) => const SupportView(),
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
                  const SizedBox(height: 24),
                  // Payment Section
                  Card(
                    color: Theme.of(context).cardColor,
                    shadowColor: Theme.of(context).shadowColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payment, color: appGreen, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Manage your payment information and settings.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
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
                                padding: const EdgeInsets.all(8.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment, size: 16),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Go to Payment Page",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

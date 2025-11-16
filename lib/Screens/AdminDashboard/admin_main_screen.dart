import 'package:flutter/material.dart';
import 'package:al_mehdi_online_school/components/admin_sidebar.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/admin_home_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/admin_dashboard_summary.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/schedule_class.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/attendance_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/chat_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/settings_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/profile_screen.dart';
import 'admin_main_provider.dart';
import 'package:provider/provider.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardSummary();
      case 1:
        return const ScheduleClass();
      case 2:
        return const AttendanceScreen();
      case 3:
        return const ChatScreen();
      case 4:
        return const SettingsScreen();
      case 5:
        return const ProfileScreen();
      default:
        return const AdminDashboardSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminMainProvider(),
      child: Consumer<AdminMainProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            body: Row(
              children: [
                AdminSidebar(
                  selectedIndex: provider.selectedIndex,
                  onItemSelected: provider.setSelectedIndex,
                ),
                Expanded(child: _getScreen(provider.selectedIndex)),
              ],
            ),
          );
        },
      ),
    );
  }
}

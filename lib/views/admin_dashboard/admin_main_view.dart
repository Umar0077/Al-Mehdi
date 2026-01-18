import 'package:al_mehdi_online_school/components/admin_sidebar.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/admin_dashboard_summary.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/sidebar_and%20bottom_tabs_views/attendance_view.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/sidebar_and%20bottom_tabs_views/chat_view.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/sidebar_and%20bottom_tabs_views/profile_view.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/sidebar_and%20bottom_tabs_views/schedule_class.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/sidebar_and%20bottom_tabs_views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/unassigned_user/admin_main_provider.dart';

class AdminMainView extends StatelessWidget {
  const AdminMainView({super.key});

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardSummary();
      case 1:
        return const ScheduleClass();
      case 2:
        return const AttendanceView();
      case 3:
        return const ChatView();
      case 4:
        return const SettingsView();
      case 5:
        return const ProfileView();
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

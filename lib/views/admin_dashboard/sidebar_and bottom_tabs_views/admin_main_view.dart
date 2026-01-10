import 'package:al_mehdi_online_school/views/admin_dashboard/sidebar_and%20bottom_tabs_views/profile_view.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/sidebar_and%20bottom_tabs_views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/custom_bottom_nabigator.dart';
import '../../../providers/admin/admin_main_screen_provider.dart';
import '../admin_home_view.dart';
import 'attendance_view.dart';
import 'chat_view.dart';

class AdminMainView extends StatelessWidget {
  const AdminMainView({super.key});

  final List<Widget> _screens = const [
    MobileVersion(),
    ChatView(),
    AttendanceView(),
    ProfileView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) async {
        final provider = Provider.of<AdminMainScreenProvider>(
          context,
          listen: false,
        );
        if (provider.selectedIndex != 0) {
          provider.setSelectedIndex(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: Provider.of<AdminMainScreenProvider>(context).selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Navbar(
          selectedIndex:
              Provider.of<AdminMainScreenProvider>(context).selectedIndex,
          onItemTapped: (index) {
            Provider.of<AdminMainScreenProvider>(
              context,
              listen: false,
            ).setSelectedIndex(index);
          },
        ),
      ),
    );
  }
}

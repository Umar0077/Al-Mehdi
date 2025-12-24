import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/profile_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/settings_screen.dart';
import 'package:flutter/material.dart';
import '../../../components/custom_bottom_nabigator.dart';
import '../admin_home_screen.dart';
import 'attendance_screen.dart';
import 'chat_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_main_screen_provider.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  final List<Widget> _screens = const [
    MobileVersion(),
    ChatScreen(),
    AttendanceScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final provider = Provider.of<AdminMainScreenProvider>(context, listen: false);
        if (provider.selectedIndex != 0) {
          provider.setSelectedIndex(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: Provider.of<AdminMainScreenProvider>(context).selectedIndex, children: _screens),
        bottomNavigationBar: Navbar(
          selectedIndex: Provider.of<AdminMainScreenProvider>(context).selectedIndex,
          onItemTapped: (index) {
            Provider.of<AdminMainScreenProvider>(context, listen: false).setSelectedIndex(index);
          },
        ),
      ),
    );
  }
}
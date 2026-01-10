import 'package:al_mehdi_online_school/components/students/student_navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/students/home/student_main_view_provider.dart';
import '../student_chat/student_chat.dart';
import '../student_classes/student_classes.dart';
import '../student_home_screen/student_home_screen_mobile.dart';
import '../student_profile/student_profile.dart';
import '../student_settings/student_settings.dart';

class StudentMainView extends StatelessWidget {
  final int initialIndex;
  const StudentMainView({super.key, this.initialIndex = 0});

  final List<Widget> _screens = const [
    StudentHomeScreenMobile(),
    StudentClassesScreen(),
    StudentChatScreen(),
    StudentSettingsScreen(),
    StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentMainViewProvider()..setIndex(initialIndex),
      child: Consumer<StudentMainViewProvider>(
        builder: (context, provider, _) {
          return WillPopScope(
            onWillPop: () async {
              if (provider.selectedIndex != 0) {
                provider.setIndex(0);
                return false;
              }
              return true;
            },
            child: Scaffold(
              body: IndexedStack(
                index: provider.selectedIndex,
                children: _screens,
              ),
              bottomNavigationBar: StudentNavbar(
                selectedIndex: provider.selectedIndex,
                onItemTapped: provider.setIndex,
              ),
            ),
          );
        },
      ),
    );
  }
}

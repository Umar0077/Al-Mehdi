import 'package:al_mehdi_online_school/students/components/student_navbar.dart';
import 'package:al_mehdi_online_school/students/student_chat/student_chat_mobile.dart';
import 'package:al_mehdi_online_school/students/student_classes/student_classes_mobile.dart';
import 'package:al_mehdi_online_school/students/student_profile/student_profile_mobile.dart';
import 'package:al_mehdi_online_school/students/student_settings/student_settings_mobile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_main_screen_provider.dart';
import '../student_chat/student_chat.dart';
import '../student_classes/student_classes.dart';
import '../student_home_screen/student_home_screen_mobile.dart';
import '../student_profile/student_profile.dart';
import '../student_settings/student_settings.dart';

class StudentMainScreen extends StatelessWidget {
  final int initialIndex;
  const StudentMainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

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
      create: (_) => StudentMainScreenProvider()..setIndex(initialIndex),
      child: Consumer<StudentMainScreenProvider>(
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
              body: IndexedStack(index: provider.selectedIndex, children: _screens),
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

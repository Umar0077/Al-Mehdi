import 'package:al_mehdi_online_school/teachers/teacher_home_screen/teacher_home_screen_mobile.dart';
import 'package:flutter/material.dart';
import '../../students/components/student_navbar.dart';
import '../teacher_chat/teacher_chat.dart';
import '../teacher_classes_screen/teacher_classes.dart';
import '../teacher_profile/teacher_profile.dart';
import '../teacher_settings/teacher_settings.dart';

class TeacherMainScreen extends StatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    TeacherHomeScreenMobile(),
    TeacherClassesScreen(),
    TeacherChatScreen(),
    TeacherSettingsScreen(),
    TeacherProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Go to Home tab instead of exiting
          });
          return false; // Prevent the app from closing
        }
        // If already on Home tab, allow the app to exit
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: StudentNavbar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}

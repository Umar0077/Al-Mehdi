import 'package:al_mehdi_online_school/students/student_settings/student_settings_mobile.dart';
import 'package:al_mehdi_online_school/students/student_settings/student_settings_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          if (width >= 900) {
            return const StudentSettingsWebView();
          } else {
            return const StudentSettingsMobileView();
          }
        } else {
          return const StudentSettingsMobileView();
        }
      },
    );
  }
}

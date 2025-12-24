import 'package:al_mehdi_online_school/teachers/teacher_notifications/teacher_notifications_mobile.dart';
import 'package:al_mehdi_online_school/teachers/teacher_notifications/teacher_notifications_web.dart';
import 'package:flutter/material.dart';

class TeacherNotificationScreen extends StatelessWidget {
  const TeacherNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const TeacherNotificationWebView();
        } else {
          return const TeacherNotificationMobileView();
        }
      },
    );
  }
}

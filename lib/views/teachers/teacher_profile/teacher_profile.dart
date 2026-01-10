import 'package:al_mehdi_online_school/views/teachers/teacher_profile/teacher_profile_mobile.dart';
import 'package:al_mehdi_online_school/views/teachers/teacher_profile/teacher_profile_web.dart';
import 'package:flutter/material.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (width >= 900) {
          // Desktop Layout
          return TeacherProfileWeb();
        } else {
          // Mobile Layout
          return TeacherProfileMobile();
        }
      },
    );
  }
}
